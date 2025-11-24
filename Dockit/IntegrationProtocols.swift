import Foundation

/// A standardized struct representing raw data before LLM processing
struct RawInboxItem: Identifiable {
    let id: String
    let content: String // The body text/html
    let sender: String
    let timestamp: Date
    let source: TaskSource
    let rawMetadata: [String: Any] // Headers, channel names, etc.
}

/// Every integration (Gmail, Slack, Jira) must conform to this
protocol SourceIntegration: AnyObject {
    var source: TaskSource { get }
    var isConnected: Bool { get }
    
    /// Authenticate the user (OAuth flow)
    func connect() async throws
    
    /// Fetch items that haven't been processed yet
    /// 'since': logic to fetch only delta updates
    func fetchNewItems(since date: Date?) async throws -> [RawInboxItem]
    
    /// Generate a deep link to open the specific item
    func getDeepLink(for itemId: String) -> URL?
}

// Error handling for integrations
enum IntegrationError: Error {
    case authenticationFailed
    case networkError(String)
    case parsingError
    case rateLimited
}
