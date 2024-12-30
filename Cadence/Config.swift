import Foundation

enum Config {
    // MARK: - API Configuration
    enum API {
        static let key = "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"
        static let baseURL = "https://api.openai.com/v1"
        static let assistantId = "asst_yuBE29K82UKAKRi6UjHe0dPq"
        
        static let headers: [String: String] = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(API.key)",
            "OpenAI-Beta": "assistants=v2"
        ]
    }
}

// End of file. No additional code.
