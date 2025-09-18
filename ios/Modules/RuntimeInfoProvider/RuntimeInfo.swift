import Foundation

public class RuntimeInfo: NSObject {
    
    // MARK: - Properties
    public let cacheburst: String
    public let nativeBinaryVersion: Int
    public let packagerPort: Int
    public let version: String
    
    // MARK: - Initialization
    public init(version: String, cacheburst: String, nativeBinaryVersion: Int, packagerPort: Int) {
        self.version = version
        self.cacheburst = cacheburst
        self.nativeBinaryVersion = nativeBinaryVersion
        self.packagerPort = packagerPort
        super.init()
    }
    
    convenience init(_ dictionary: [String: Any]) {
        let version = dictionary["version"] as? String ?? ""
        let cacheburst = dictionary["cachebust"] as? String ?? ""
        let nativeBinaryVersion = dictionary["nativeBinaryVersion"] as? Int ?? 0
        let packagerPort = dictionary["packagerPort"] as? Int ?? 0
        self.init(
            version: version,
            cacheburst: cacheburst,
            nativeBinaryVersion: nativeBinaryVersion,
            packagerPort: packagerPort
        )
    }
}

//Checked
