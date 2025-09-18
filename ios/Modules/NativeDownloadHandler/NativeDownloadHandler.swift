import Foundation
import React

fileprivate func formatMessage(_ message: String) -> String {
    return "\(String(describing: NativeDownloadHandler.self)): \(message)"
}

class NativeDownloadHandler: NSObject {
    
    let mimeType: String?
    let connectionTimeout: Int
    let doneCallback: (() -> Void)?
    let progressCallback: ((Int64, Int64) -> Void)?
    let failCallback: ((Error) -> Void)?
    var downloadPath: String = ""
    
    init(_
         config: [String: Any],
         doneCallback: @escaping () -> Void,
         progressCallback: ((Int64, Int64) -> Void)?,
         failCallback: @escaping (Error) -> Void
    ) {
        if let timeoutValue = config["connectionTimeout"] as? NSNumber {
            self.connectionTimeout = timeoutValue.intValue / 1000
        } else {
            self.connectionTimeout = 10
        }
        self.mimeType = config["mimeType"] as? String
        self.doneCallback = doneCallback
        self.progressCallback = progressCallback
        self.failCallback = failCallback
        super.init()
    }
    
    func download(_ urlString: String, downloadPath: String) {
        self.downloadPath = downloadPath
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        guard let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrlString) else {
            let error = NSError(domain: NSURLErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            failCallback?(error)
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TimeInterval(connectionTimeout))
        let downloadTask = session.downloadTask(with: request)
        downloadTask.resume()
    }
}

// MARK: - URLSessionDownloadDelegate
extension NativeDownloadHandler: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        
        // Check MIME type if specified
        if let expectedMimeType = mimeType,
           let responseMimeType = downloadTask.response?.mimeType,
           responseMimeType != expectedMimeType {
            let error = NSError(domain: UserDefaults.argumentDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "MIME type not expected."])
            failCallback?(error)
            return
        }
        
        // Check if file already exists
        if fileManager.fileExists(atPath: downloadPath) {
            let error = NSError(domain: NSURLErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "File already exists in the same path."])
            failCallback?(error)
            return
        }
        
        // Create directory if needed
        let directoryUrl = URL(fileURLWithPath: (downloadPath as NSString).deletingLastPathComponent)
        do {
            try fileManager.createDirectory(
                at: directoryUrl,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            NSLog("%@", formatMessage("Could not create path: \(error)"))
            failCallback?(error)
            return
        }
        
        // Move downloaded file to final location
        let destinationUrl = URL(fileURLWithPath: downloadPath)
        let backupName = "\((downloadPath as NSString).lastPathComponent)_backup"
        
        do {
            _ = try fileManager.replaceItem(
                at: destinationUrl,
                withItemAt: location,
                backupItemName: backupName,
                options: .usingNewMetadataOnly,
                resultingItemURL: nil
            )
            NSLog("%@", formatMessage("File saved successfully"))
            doneCallback?()
        } catch {
            try? fileManager.removeItem(at: destinationUrl)
            NSLog("%@", formatMessage("Could not copy path: \(error)"))
            failCallback?(error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        NSLog("%@", formatMessage("Bytes written \(totalBytesWritten)"))
        progressCallback?(totalBytesWritten, totalBytesExpectedToWrite)
    }
}

// MARK: - URLSessionTaskDelegate
extension NativeDownloadHandler: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        NSLog("%@", formatMessage("Could not download: \(error)"))
        failCallback?(error)
    }
}

// MARK: - React Native Bridge Module
@objcMembers
public class NativeDownloadModule: NSObject {
    
    private static let ERROR_DOWNLOAD_FAILED = "ERROR_DOWNLOAD_FAILED"
    
    public func download(
        _ url: String,
        downloadPath: String,
        config: [String: Any],
        onProgress: @escaping ([String: Int64]) -> Void,
        promise: Promise
    ) {
        
        let handler = NativeDownloadHandler(
            config,
            doneCallback: {
                promise.resolve(nil)
            },
            progressCallback: { received, total in
                onProgress(["receivedBytes": received, "totalBytes": total])
            },
            failCallback: { error in
                promise.reject(NativeDownloadModule.ERROR_DOWNLOAD_FAILED, formatMessage(error.localizedDescription), error)
            }
        )
        
        handler.download(url, downloadPath: downloadPath)
    }
}

//Checked
