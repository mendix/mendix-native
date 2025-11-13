import Foundation

public class RuntimeInfoProvider: NSObject {
    
    // MARK: - Public Methods
    public static func getRuntimeInfo(_ runtimeURL: URL?, completionHandler: @escaping (RuntimeInfoResponse) -> Void) {
        guard let runtimeURL = runtimeURL else {
            return onMainQueue(.inaccessible, handler: completionHandler)
        }
        URLSession.shared.dataTask(with: createRequest(runtimeURL)) { data, response, error in
            if error != nil {
                return onMainQueue(.inaccessible, handler: completionHandler)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return onMainQueue(.failed, handler: completionHandler)
            }
            
            if !isSuccessStatusCode(httpResponse.statusCode) {
                return onMainQueue(.failed, handler: completionHandler)
            }
            
            guard let data = data else {
                return onMainQueue(.failed, handler: completionHandler)
            }
            
            do {
                guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return onMainQueue(.failed, handler: completionHandler)
                }
                
                let runtimeInfo = RuntimeInfo(jsonDictionary)
                return onMainQueue(.success(runtimeInfo), handler: completionHandler)
            } catch {
                return onMainQueue(.failed, handler: completionHandler)
            }
        }.resume()
    }
    
    // MARK: - Private Helper Methods
    private static func onMainQueue(_ status: RuntimeInfoResponseStatus, handler: @escaping (RuntimeInfoResponse) -> Void) {
        DispatchQueue.main.async {
            handler(status.response)
        }
    }
    
    private static func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        return statusCode >= 200 && statusCode <= 299
    }
    
    private static func createRequest(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.addValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = "{\"action\": \"info\"}".data(using: .utf8)
        return request
    }
}
