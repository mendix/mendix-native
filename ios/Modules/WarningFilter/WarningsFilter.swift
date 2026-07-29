import Foundation

@objc public enum WarningsFilter: Int, CaseIterable {
    case all = 0
    case partial = 1
    case none = 2
    
    /// String representation of the WarningsFilter value
    var stringValue: String {
        switch self {
        case .all:
            return "all"
        case .partial:
            return "partial"
        case .none:
            return "none"
        }
    }
}

// MARK: - CustomStringConvertible
extension WarningsFilter: CustomStringConvertible {
    public var description: String {
        return stringValue
    }
}
