import Foundation
import SwiftData

// MARK: - Network Protocols
protocol APIClient {
    func sendRequest<T: Decodable>(_ request: APIRequest) async throws -> T
    func streamRequest<T: Decodable>(_ request: APIRequest, onReceive: @escaping @MainActor (T) -> Void) async throws
}

protocol APIRequest {
    var path: String { get }
    var method: String { get }
    var headers: [String: String] { get }
    var queryItems: [String: String]? { get }
    var body: [String: Any]? { get }
    var stream: Bool { get }
}

extension APIRequest {
    var stream: Bool { false }
}

// MARK: - Network Errors
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed(Error)
    case maxRetriesExceeded
}

// MARK: - OpenAI Service
class OpenAIService: APIClient {
    // MARK: - Dependencies
    private let networkMonitor: NetworkMonitor
    private let errorHandler: ErrorHandling
    private let modelContext: ModelContext
    
    // MARK: - Properties
    private let maxRetries = 3
    private let retryDelay: UInt64 = 2_000_000_000 // 2 seconds
    
    // MARK: - Initialization
    init(networkMonitor: NetworkMonitor, errorHandler: ErrorHandling, modelContext: ModelContext) {
        self.networkMonitor = networkMonitor
        self.errorHandler = errorHandler
        self.modelContext = modelContext
    }
    
    func streamRequest<T>(_ request: APIRequest, onReceive: @escaping @MainActor (T) -> Void) async throws where T: Decodable {
        // Only check network if explicitly disconnected
        if case .disconnected = networkMonitor.status {
            throw AppError.network(.invalidResponse)
        }
        
        guard var urlComponents = URLComponents(string: Config.API.baseURL + request.path) else {
            throw NetworkError.invalidURL
        }
        
        if let queryItems = request.queryItems {
            urlComponents.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.timeoutInterval = 30
        
        let headers = Config.API.headers.merging(request.headers) { _, new in new }
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        if let body = request.body {
            var streamingBody = body
            streamingBody["stream"] = true
            let jsonData = try JSONSerialization.data(withJSONObject: streamingBody)
            urlRequest.httpBody = jsonData
        }
        
        let session = URLSession.shared
        let (result, _) = try await session.bytes(for: urlRequest)
        
        let decoder = JSONDecoder()
        var buffer = ""
        var isWaitingForResponse = false
        
        for try await line in result.lines {
            // Check network availability during streaming
            guard networkMonitor.isConnected else {
                throw AppError.network(.invalidResponse)
            }
            
            guard !line.isEmpty else { continue }
            
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if jsonString == "[DONE]" {
                    if isWaitingForResponse {
                        // Wait briefly for the final response
                        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
                        try await retrieveAndStreamFinalResponse(request: request, onReceive: onReceive)
                    }
                    continue
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else { continue }
                
                do {
                    // First try to decode as RunResponse to check for required_action
                    if let runResponse = try? decoder.decode(RunResponse.self, from: jsonData),
                       runResponse.status == "requires_action",
                       let action = runResponse.requiredAction,
                       action.type == "submit_tool_outputs",
                       let tools = action.submitToolOutputs {
                        
                        // Handle tool calls
                        try await handleToolCalls(tools.toolCalls,
                                                threadId: request.path.components(separatedBy: "/")[2],
                                                runId: runResponse.id)
                        isWaitingForResponse = true
                        continue
                    }
                    
                    // Then try to decode as MessageContent for streaming text
                    if T.self == String.self {
                        if let messageData = try? decoder.decode(StreamResponse.self, from: jsonData) {
                            if let content = messageData.delta?.content?.first?.text?.value {
                                buffer += content
                                let currentBuffer = buffer
                                DispatchQueue.main.async {
                                    onReceive(currentBuffer as! T)
                                }
                            } else if let content = messageData.data?.content?.first?.text?.value {
                                buffer += content
                                let currentBuffer = buffer
                                DispatchQueue.main.async {
                                    onReceive(currentBuffer as! T)
                                }
                            }
                        }
                    } else {
                        let decoded = try decoder.decode(T.self, from: jsonData)
                        DispatchQueue.main.async {
                            onReceive(decoded)
                        }
                    }
                } catch {
                    continue
                }
            }
        }
    }
    
    private func retrieveAndStreamFinalResponse<T>(
        request: APIRequest,
        onReceive: @escaping @MainActor (T) -> Void
    ) async throws where T: Decodable {
        let threadId = request.path.components(separatedBy: "/")[2]
        let messagesRequest = ListMessagesRequest(threadId: threadId, limit: 1, order: "desc")
        let response: ListMessagesResponse = try await sendRequest(messagesRequest)
        
        if let lastMessage = response.data.first,
           let content = lastMessage.content.first?.text?.value,
           T.self == String.self {
            DispatchQueue.main.async {
                onReceive(content as! T)
            }
        }
    }
    
    private func handleToolCalls(_ toolCalls: [ToolCall], threadId: String, runId: String) async throws {
        var outputs: [[String: String]] = []
        
        for call in toolCalls {
            if call.type == "function" {
                do {
                    print("Function called: \(call.function.name) with arguments: \(call.function.arguments)")
                    let result = try await executeFunction(name: call.function.name, arguments: call.function.arguments)
                    outputs.append(["tool_call_id": call.id, "output": result])
                } catch {
                    throw error
                }
            }
        }
        
        if !outputs.isEmpty {
            let request = SubmitToolOutputsRequest(threadId: threadId, runId: runId, toolOutputs: outputs)
            let _: RunResponse = try await sendRequest(request)
        }
    }
    
    private func executeFunction(name: String, arguments: String) async throws -> String {
        guard let jsonData = arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NetworkError.decodingFailed(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid function arguments"]))
        }
        
        switch name {
        case "create_workout":
            // Define WorkoutArgs struct in scope
            struct WorkoutArgs: Codable {
                let type: WorkoutType
                let duration: Int?
                let notes: String?
            }
            
            guard let argsData = try? JSONSerialization.data(withJSONObject: args),
                  let workoutArgs = try? JSONDecoder().decode(WorkoutArgs.self, from: argsData) else {
                throw NetworkError.decodingFailed(NSError(domain: "", 
                                                        code: -1, 
                                                        userInfo: [NSLocalizedDescriptionKey: "Failed to decode workout arguments"]))
            }
            
            // Create and save workout
            @MainActor func saveWorkout() async throws -> String {
                print("Creating workout with type: \(workoutArgs.type.displayName), duration: \(workoutArgs.duration ?? 0)")
                
                let workout = Workout(
                    type: workoutArgs.type,
                    duration: workoutArgs.duration,
                    notes: workoutArgs.notes
                )
                
                print("Inserting workout into context")
                modelContext.insert(workout)
                
                do {
                    try modelContext.save()
                    print("Successfully saved workout to context")
                } catch {
                    print("Failed to save workout: \(error)")
                    throw error
                }
                
                let durationText = workoutArgs.duration != nil ? " (\(workoutArgs.duration!) minutes)" : ""
                return "Successfully logged your \(workout.type.displayName) workout\(durationText)"
            }
            
            return try await saveWorkout()
            
        default:
            throw NetworkError.decodingFailed(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown function: \(name)"]))
        }
    }
    
    func sendRequest<T>(_ request: APIRequest) async throws -> T where T : Decodable {
        // Only check network if explicitly disconnected
        if case .disconnected = networkMonitor.status {
            throw AppError.network(.invalidResponse)
        }
        
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await performRequest(request)
            } catch {
                lastError = error
                errorHandler.log(error)
                
                // Only check network if explicitly disconnected
                if case .disconnected = networkMonitor.status {
                    throw AppError.network(.invalidResponse)
                }
                
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(attempt))
                }
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    private func performRequest<T: Decodable>(_ request: APIRequest) async throws -> T {
        guard var urlComponents = URLComponents(string: Config.API.baseURL + request.path) else {
            throw NetworkError.invalidURL
        }
        
        if let queryItems = request.queryItems {
            urlComponents.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.timeoutInterval = 15 // Reduced timeout
        
        let headers = Config.API.headers.merging(request.headers) { _, new in new }
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        if let body = request.body {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            urlRequest.httpBody = jsonData
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as NetworkError {
            throw error
        } catch let error as DecodingError {
            print("Decoding Error: \(error)")
            throw NetworkError.decodingFailed(error)
        } catch {
            print("Network Error: \(error)")
            throw NetworkError.requestFailed(error)
        }
    }
}

struct StreamResponse: Codable {
    let id: String
    let object: String
    let event: String?
    let data: StreamData?
    let delta: StreamDelta?
}

struct StreamData: Codable {
    let role: String?
    let content: [MessageContent]?
}

struct StreamDelta: Codable {
    let role: String?
    let content: [MessageContent]?
}
