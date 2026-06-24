import Foundation

public struct RuntimeInfoResponse {
    // MARK: - Properties
    public let status: String
    public let runtimeInfo: RuntimeInfo?
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
