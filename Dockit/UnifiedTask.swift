import Foundation
import SwiftData

enum TaskPriority: Int, Codable, Comparable {
    case critical = 4
    case high = 3
    case medium = 2
    case low = 1
    
    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var label: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

enum TaskSource: String, Codable {
    case gmail = "Gmail"
    case outlook = "Outlook"
    case slack = "Slack"
    case jira = "Jira"
    case linear = "Linear"
    case notion = "Notion"
    
    var iconName: String {
        // SF Symbols or custom asset names
        switch self {
        case .gmail: return "envelope.fill"
        case .slack: return "bubble.left.and.bubble.right.fill"
        default: return "circle.grid.3x3.fill"
        }
    }
}

@Model
final class UnifiedTask {
    // The unique ID from the external system (e.g., Gmail Message ID) prevents duplicates
    @Attribute(.unique) var externalId: String
    
    // LLM Generated Content
    var title: String
    var summary: String
    var actionItem: String // specific next step
    
    // Metadata
    var source: TaskSource
    var priority: TaskPriority
    var deepLink: URL? // URLScheme to open the original app (slack://...)
    
    // State
    var isCompleted: Bool = false
    var createdAt: Date
    var deadline: Date?
    
    init(externalId: String, title: String, summary: String, actionItem: String, source: TaskSource, priority: TaskPriority, deepLink: URL? = nil, deadline: Date? = nil) {
        self.externalId = externalId
        self.title = title
        self.summary = summary
        self.actionItem = actionItem
        self.source = source
        self.priority = priority
        self.deepLink = deepLink
        self.createdAt = Date()
        self.deadline = deadline
    }
}
