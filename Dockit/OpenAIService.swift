import Foundation

actor OpenAILLMService: LLMService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func analyze(item: RawInboxItem) async throws -> LLMTaskAnalysis {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 1. Construct the System Prompt (The Brains)
        let systemPrompt = """
        You are an elite executive assistant. Your job is to process incoming messages into a unified task list.
        
        RULES:
        1. TITLE: Rewrite the subject line to be action-oriented and clear. Remove "Fwd:", "Re:", and generic words.
        2. SUMMARY: Summarize the context in 1-2 sentences.
        3. ACTION: Extract the single most important next step for the user.
        4. PRIORITY: Rate 1-4 (1=Low, 4=Critical). strict deadlines or VIPs = High/Critical.
        5. OUTPUT: You must output VALID JSON only. No markdown.
        """
        
        // 2. Construct the User Message
        let userContent = """
        Sender: \(item.sender)
        Source: \(item.source.rawValue)
        Timestamp: \(item.timestamp)
        Raw Content:
        \(item.content)
        """
        
        let payload: [String: Any] = [
            "model": "gpt-4o-mini", // Fast and cheap for high volume
            "response_format": ["type": "json_object"], // Enforces JSON
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // 3. Fire Network Request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw IntegrationError.networkError("API Error: \(response)")
        }
        
        // 4. Parse the OpenAI Response
        let apiResponse = try JSONDecoder().decode(OpenAIAPIResponse.self, from: data)
        guard let jsonString = apiResponse.choices.first?.message.content,
              let jsonData = jsonString.data(using: .utf8) else {
            throw IntegrationError.parsingError
        }
        
        let analysis = try JSONDecoder().decode(LLMAnalysisResponse.self, from: jsonData)
        
        // 5. Map to Domain Model
        return LLMTaskAnalysis(
            title: analysis.cleanTitle,
            summary: analysis.summary,
            actionItem: analysis.actionItem,
            priority: TaskPriority(rawValue: analysis.priorityScore) ?? .medium,
            estimatedDeadline: ISO8601DateFormatter().date(from: analysis.deadlineISO ?? "")
        )
    }
}

// Helper structs for OpenAI API shape
private struct OpenAIAPIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
