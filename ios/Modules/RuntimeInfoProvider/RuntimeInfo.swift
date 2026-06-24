import Foundation

public struct RuntimeInfo {
    
    // MARK: - Properties
    public let version: String
    public let cacheburst: String
    public let nativeBinaryVersion: Int
    public let packagerPort: Int
    
    static func initWith(_ dictionary: [String: Any]) -> Self {
        let version = dictionary["version"] as? String ?? ""
        let cacheburst = dictionary["cachebust"] as? String ?? ""
        let nativeBinaryVersion = dictionary["nativeBinaryVersion"] as? Int ?? 0
        let packagerPort = dictionary["packagerPort"] as? Int ?? 0
        return RuntimeInfo(
            version: version,
            cacheburst: cacheburst,
            nativeBinaryVersion: nativeBinaryVersion,
            packagerPort: packagerPort
        )
    }
}
