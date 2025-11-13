import Foundation

public class RuntimeInfoResponse: NSObject {
    
    // MARK: - Properties
    public let status: String
    public let runtimeInfo: RuntimeInfo?
    
    // MARK: - Initialization
    public init(status: String, runtimeInfo: RuntimeInfo?) {
        self.status = status
        self.runtimeInfo = runtimeInfo
        super.init()
    }
}


public enum RuntimeInfoResponseStatus {
    case success(RuntimeInfo)
    case failed
    case inaccessible
    
    var response : RuntimeInfoResponse {
        switch self {
        case .success(let info):
            return RuntimeInfoResponse(status: "SUCCESS", runtimeInfo: info)
        case .failed:
            return RuntimeInfoResponse(status: "FAILED", runtimeInfo: nil)
        case .inaccessible:
            return RuntimeInfoResponse(status: "INACCESSIBLE", runtimeInfo: nil)
        }
    }
}
