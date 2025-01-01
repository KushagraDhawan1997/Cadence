import Foundation

// MARK: - Base Models
struct AssistantModel: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let name: String?
    let description: String?
    let model: String
    let instructions: String?
    
    enum CodingKeys: String, CodingKey {
        case id, object, model, name, description, instructions
        case createdAt = "created_at"
    }
}

struct ThreadModel: Codable, Equatable, Identifiable {
    let id: String
    let object: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case id, object
        case createdAt = "created_at"
    }
}

// MARK: - Streaming Models
struct RunStreamResponse: Codable, Identifiable {
    let id: String
    let object: String
    let createdAt: Int
    let event: String?
    let data: StreamMessageData?
    
    enum CodingKeys: String, CodingKey {
        case id, object, event, data
        case createdAt = "created_at"
    }
}

struct StreamMessageData: Codable {
    let id: String?
    let object: String?
    let createdAt: Int?
    let threadId: String?
    let role: String?
    let content: [MessageContent]?
    let status: String?
    let completedAt: Int?
    let usage: Usage?
    
    enum CodingKeys: String, CodingKey {
        case id, object, role, content, status, usage
        case createdAt = "created_at"
        case threadId = "thread_id"
        case completedAt = "completed_at"
    }
}

struct MessageDeltaResponse: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String?
    let role: String?
    let content: [MessageContent]?
    let delta: DeltaContent
    
    enum CodingKeys: String, CodingKey {
        case id, object, delta, role, content
        case createdAt = "created_at"
        case threadId = "thread_id"
    }
}

struct DeltaContent: Codable {
    let type: String?
    let text: TextContent?
    let content: [ContentDelta]?
}

struct ContentDelta: Codable {
    let type: String
    let text: TextContent?
    let index: Int?
}

struct Usage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Function Models
struct Function: Codable {
    let name: String
    let description: String
    let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name, description, parameters
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        parameters = [:]
    }
}

// MARK: - Request Models
struct CreateAssistantRequest: APIRequest {
    let model: String
    let name: String?
    let description: String?
    let instructions: String?
    
    var path: String { "/assistants" }
    var method: String { "POST" }
    var headers: [String : String] { [:] }
    var queryItems: [String : String]? { nil }
    var body: [String : Any]? {
        var body: [String: Any] = ["model": model]
        name.map { body["name"] = $0 }
        description.map { body["description"] = $0 }
        instructions.map { body["instructions"] = $0 }
        return body
    }
}

struct CreateThreadRequest: APIRequest {
    let messages: [[String: Any]]?
    
    var path: String { "/threads" }
    var method: String { "POST" }
    var headers: [String : String] { [:] }
    var queryItems: [String : String]? { nil }
    var body: [String : Any]? {
        guard let messages = messages else { return nil }
        return ["messages": messages]
    }
}

struct CreateMessageRequest: APIRequest {
    let threadId: String
    let content: String
    let fileIds: [String]?
    
    var path: String { "/threads/\(threadId)/messages" }
    var method: String { "POST" }
    var headers: [String : String] { [:] }
    var queryItems: [String : String]? { nil }
    var body: [String : Any]? {
        var body: [String: Any] = [
            "role": "user",
            "content": content
        ]
        fileIds.map { body["file_ids"] = $0 }
        return body
    }
}

struct CreateRunRequest: APIRequest {
    let threadId: String
    var stream: Bool { true }
    
    var path: String { "/threads/\(threadId)/runs" }
    var method: String { "POST" }
    var headers: [String : String] { [:] }
    var queryItems: [String : String]? { nil }
    var body: [String : Any]? {
        [
            "assistant_id": Config.API.assistantId,
            "model": "gpt-4-1106-preview"
        ]
    }
}

struct RetrieveRunRequest: APIRequest {
    let threadId: String
    let runId: String
    
    var path: String { "/threads/\(threadId)/runs/\(runId)" }
    var method: String { "GET" }
    var headers: [String : String] { [:] }
    var queryItems: [String : String]? { nil }
    var body: [String : Any]? { nil }
}

struct ListMessagesRequest: APIRequest {
    let threadId: String
    let limit: Int
    let order: String
    
    init(threadId: String, limit: Int = 100, order: String = "asc") {
        self.threadId = threadId
        self.limit = limit
        self.order = order
    }
    
    var path: String { "/threads/\(threadId)/messages" }
    var method: String { "GET" }
    var headers: [String : String] { [:] }
    var queryItems: [String : String]? {
        ["limit": "\(limit)", "order": order]
    }
    var body: [String : Any]? { nil }
}

struct SubmitToolOutputsRequest: APIRequest {
    let threadId: String
    let runId: String
    let toolOutputs: [[String: String]]
    
    var path: String { "/threads/\(threadId)/runs/\(runId)/submit_tool_outputs" }
    var method: String { "POST" }
    var headers: [String : String] { [:] }
    var queryItems: [String : String]? { nil }
    var body: [String : Any]? {
        ["tool_outputs": toolOutputs]
    }
}

// MARK: - Response Models
struct MessageResponse: Codable, Equatable, Identifiable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String
    let role: String
    let content: [MessageContent]
    
    enum CodingKeys: String, CodingKey {
        case id, object, role, content
        case createdAt = "created_at"
        case threadId = "thread_id"
    }
}

struct MessageContent: Codable, Equatable {
    let type: String
    let text: TextContent?
}

struct TextContent: Codable, Equatable {
    let value: String
    let annotations: [String]?
}

struct RunResponse: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String
    let assistantId: String
    let status: String
    let requiredAction: RequiredAction?
    
    enum CodingKeys: String, CodingKey {
        case id, object, status
        case createdAt = "created_at"
        case threadId = "thread_id"
        case assistantId = "assistant_id"
        case requiredAction = "required_action"
    }
}

struct RequiredAction: Codable {
    let type: String
    let submitToolOutputs: SubmitToolOutputs?
    
    enum CodingKeys: String, CodingKey {
        case type
        case submitToolOutputs = "submit_tool_outputs"
    }
}

struct SubmitToolOutputs: Codable {
    let toolCalls: [ToolCall]
    
    enum CodingKeys: String, CodingKey {
        case toolCalls = "tool_calls"
    }
}

struct ToolCall: Codable {
    let id: String
    let type: String
    let function: FunctionCall
}

struct FunctionCall: Codable {
    let name: String
    let arguments: String
}

struct ListMessagesResponse: Codable {
    let object: String
    let data: [MessageResponse]
    let firstId: String?
    let lastId: String?
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case object, data
        case firstId = "first_id"
        case lastId = "last_id"
        case hasMore = "has_more"
    }
}
