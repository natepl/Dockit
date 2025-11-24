import Foundation

struct LLMAnalysisResponse: Codable {
    let cleanTitle: String
    let summary: String
    let actionItem: String
    let priorityScore: Int // 1 (Low) to 4 (Critical)
    let deadlineISO: String? // ISO 8601 Date string or null
}
