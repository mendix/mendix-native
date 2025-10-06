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
    
    /// Static array for Objective-C compatibility (equivalent to WarningsFilter_toString)
    static let toString: [String] = [
        "all",
        "partial",
        "none"
    ]
    
    /// Get string representation for a given index (Objective-C compatibility)
    static func string(for index: Int) -> String? {
        guard index >= 0 && index < toString.count else {
            return nil
        }
        return toString[index]
    }
    
    /// Create WarningsFilter from string value
    static func from(string: String) -> WarningsFilter? {
        switch string.lowercased() {
        case "all":
            return .all
        case "partial":
            return .partial
        case "none":
            return WarningsFilter.none
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible
extension WarningsFilter: CustomStringConvertible {
    public var description: String {
        return stringValue
    }
}

// MARK: - Objective-C Bridge Functions
@objc class WarningsFilterBridge: NSObject {
    /// Bridge function to get string representation (for Objective-C compatibility)
    @objc static func toString(for filter: WarningsFilter) -> String {
        return filter.stringValue
    }
    
    /// Bridge function to get WarningsFilter from index (for Objective-C compatibility)
    @objc static func filter(for index: Int) -> WarningsFilter {
        guard let filter = WarningsFilter(rawValue: index) else {
            return .none // Default fallback
        }
        return filter
    }
}

//Checked
