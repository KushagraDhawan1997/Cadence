import Foundation

// MARK: - Network Protocols
protocol APIClient {
    func sendRequest<T: Decodable>(_ request: APIRequest) async throws -> T
}

protocol APIRequest {
    var path: String { get }
    var method: String { get }
    var headers: [String: String] { get }
    var queryItems: [String: String]? { get }
    var body: [String: Any]? { get }
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
    private let maxRetries = 3
    private let retryDelay: UInt64 = 2_000_000_000 // 2 seconds
    
    init() {
        // No need for apiKey parameter anymore
    }
    
    func sendRequest<T>(_ request: APIRequest) async throws -> T where T : Decodable {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await performRequest(request)
            } catch {
                lastError = error
                print("Attempt \(attempt) failed: \(error)")
                
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay)
                    print("Retrying request...")
                }
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    private func performRequest<T: Decodable>(_ request: APIRequest) async throws -> T {
        guard var urlComponents = URLComponents(string: Config.API.baseURL + request.path) else {
            throw NetworkError.invalidURL
        }
        
        // Add query items if present
        if let queryItems = request.queryItems {
            urlComponents.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.timeoutInterval = 30 // Increase timeout to 30 seconds
        
        // Merge request headers with default API headers
        let headers = Config.API.headers.merging(request.headers) { _, new in new }
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Add body if present and encode it properly
        if let body = request.body {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            urlRequest.httpBody = jsonData
            print("Request URL: \(url)")
            print("Request Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("Response Status Code: \(httpResponse.statusCode)")
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            
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
