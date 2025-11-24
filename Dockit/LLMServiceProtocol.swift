import Foundation

struct LLMTaskAnalysis {
    let title: String
    let summary: String
    let actionItem: String
    let priority: TaskPriority
    let estimatedDeadline: Date?
}

protocol LLMService {
    /// Takes raw messy text and turns it into structured task data
    func analyze(item: RawInboxItem) async throws -> LLMTaskAnalysis
}
