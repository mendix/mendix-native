import Foundation

public class AppUrl: NSObject {
    
    // MARK: - Constants
    public static let defaultPackagerPort = 8083
    private static let queryStringForDevMode = "platform=ios&dev=true&minify=false"
    private static let queryStringProduction = "platform=ios&dev=false&minify=true"
    private static let defaultUrlString = "http://localhost:8080"
    
    static func ensurePort(_ port: Int) -> Int {
        return port != 0 ? port : defaultPackagerPort
    }
    
    public static func forBundle(_ url: String, port: Int, isDebuggingRemotely: Bool, isDevModeEnabled: Bool) -> URL {
        let query = isDevModeEnabled ? queryStringForDevMode : queryStringProduction
        guard let url = createUrl(url, path: .bundle, port: port, query: query, concatPath: true) else {
            fatalError("Invalid bundle URL")
        }
        return url
    }
    
    public static func forRuntime(_ url: String) -> URL {
        guard let url = createUrl(url, path: .runtime) else {
            fatalError("Invalid runtime URL")
        }
        return url
    }
    
    public static func forValidation(_ url: String) -> URL? {
        return createUrl(url, path: .validation)
    }
    
    public static func forRuntimeInfo(_ url: String) -> URL? {
        return createUrl(url, path: .runtimeInfo)
    }
    
    public static func forPackagerStatus(_ url: String, port: Int) -> URL? {
        return createUrl(url, path: .packagerStatus, port: port)
    }
    
    public static func isValid(_ url: String) -> Bool {
        let trimmedUrl = url.trimmingCharacters(in: .whitespaces)
        
        if trimmedUrl.count < 1 {
            return false
        }
        
        let processedUrl = ensureProtocol(removeTrailingSlash(trimmedUrl))
        guard let urlComponents = URLComponents(string: processedUrl) else {
            return false
        }
        
        return (urlComponents.queryItems?.isEmpty ?? true) && (urlComponents.path.isEmpty || urlComponents.path == "/")
    }
    
    // MARK: - Private Helper Methods
    private static func createUrl(_ url: String, path: UrlPath?, port: Int? = nil, query: String? = nil, concatPath: Bool = false) -> URL? {
        let processedUrl = ensureProtocol(removeTrailingSlash(url))
        guard var components = URLComponents(string: processedUrl) ?? URLComponents(string: defaultUrlString) else {
            return nil
        }
        if let pathUrl = path?.rawValue {
            components.path = concatPath ? (components.path + pathUrl) : pathUrl
        }
        if let port {
            components.port = ensurePort(port)
        }
        if let query {
            components.query = query
        }
        return URL(string: components.string ?? "")
    }
    
    private static func ensureProtocol(_ url: String) -> String {
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        }
        return "http://" + url
    }
    
    private static func removeTrailingSlash(_ url: String) -> String {
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedUrl.hasSuffix("/") {
            return String(trimmedUrl.dropLast())
        }
        return trimmedUrl
    }
}

public enum UrlPath: String, Codable {
    case runtime = "/"
    case validation = ""
    case runtimeInfo = "/xas/"
    case packagerStatus = "/status"
    case bundle = "/index.bundle"
}

//Checked
