import Foundation
import React

fileprivate func formatMessage(_ message: String) -> String {
    return "\(String(describing: NativeDownloadHandler.self)): \(message)"
}

/// A download failure with the rejection code passed to JS. The codes match Android's.
struct NativeDownloadError: LocalizedError {
    static let ERROR_DOWNLOAD_FAILED = "ERROR_DOWNLOAD_FAILED"
    static let FILE_ALREADY_EXISTS = "FILE_ALREADY_EXISTS"
    static let IO_EXCEPTION = "IO_EXCEPTION"
    static let FS_ACCESS_EXCEPTION = "FS_ACCESS_EXCEPTION"

    let code: String
    let message: String
    let underlyingError: Error?

    init(code: String, message: String, underlyingError: Error? = nil) {
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
    }

    var errorDescription: String? { message }

    /// Maps a file system error to FS_ACCESS_EXCEPTION for permission errors, IO_EXCEPTION otherwise.
    static func fileSystem(_ error: Error, message: String) -> NativeDownloadError {
        let permissionCodes: Set<Int> = [CocoaError.fileReadNoPermission.rawValue, CocoaError.fileWriteNoPermission.rawValue]
        let nsError = error as NSError
        let code = nsError.domain == NSCocoaErrorDomain && permissionCodes.contains(nsError.code) ? FS_ACCESS_EXCEPTION : IO_EXCEPTION
        return NativeDownloadError(code: code, message: message, underlyingError: error)
    }

    /// The rejection code for any error passed to a download fail callback.
    static func code(for error: Error) -> String {
        (error as? NativeDownloadError)?.code ?? ERROR_DOWNLOAD_FAILED
    }
}

/// Compares type and subtype only, so parameters such as `charset` are ignored.
/// A response without a MIME type doesn't match.
func mimeTypeMatches(_ actual: String?, expected: String) -> Bool {
    func essence(_ mimeType: String) -> String {
        mimeType.split(separator: ";", maxSplits: 1).first.map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? ""
    }
    guard let actual else { return false }
    return essence(actual) == essence(expected)
}

class NativeDownloadHandler: NSObject {
    
    let mimeType: String?
    let connectionTimeout: TimeInterval
    let doneCallback: (() -> Void)?
    let progressCallback: ((Int64, Int64) -> Void)?
    let failCallback: ((Error) -> Void)?
    var downloadPath: String = ""
    
    init(
        connectionTimeout: NSNumber?,
        mimeType: String?,
        doneCallback: @escaping () -> Void,
        progressCallback: ((Int64, Int64) -> Void)?,
        failCallback: @escaping (Error) -> Void
    ) {
        if let connectionTimeout {
            // Milliseconds, as on Android; keep fractions so sub-second timeouts don't become 0.
            self.connectionTimeout = connectionTimeout.doubleValue / 1000
        } else {
            self.connectionTimeout = 10
        }
        self.mimeType = mimeType
        self.doneCallback = doneCallback
        self.progressCallback = progressCallback
        self.failCallback = failCallback
        super.init()
    }
    
    func download(_ urlString: String, downloadPath: String) {
        self.downloadPath = downloadPath
        
        guard let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrlString) else {
            failCallback?(NativeDownloadError(code: NativeDownloadError.ERROR_DOWNLOAD_FAILED, message: "Invalid URL"))
            return
        }
        
        // Fail before downloading, as Android does, so no bandwidth is wasted. Checked again after the download.
        if FileManager.default.fileExists(atPath: downloadPath) {
            failCallback?(NativeDownloadError(code: NativeDownloadError.FILE_ALREADY_EXISTS, message: "File already exists in the same path."))
            return
        }
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: connectionTimeout)
        let downloadTask = session.downloadTask(with: request)
        downloadTask.resume()
        // The session retains its delegate (self) until invalidated; release both once the task is done.
        session.finishTasksAndInvalidate()
    }
}

// MARK: - URLSessionDownloadDelegate
extension NativeDownloadHandler: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        
        // Validate the HTTP status code. URLSession's download task writes the response body
        // to `location` even for error responses (e.g. 404/500), so without this check an
        // HTML/JSON error body would be saved as the "downloaded" file and later fail to unzip
        // with a misleading error. Fail explicitly with the status code instead.
        if let httpResponse = downloadTask.response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            let error = NativeDownloadError(
                code: NativeDownloadError.ERROR_DOWNLOAD_FAILED,
                message: "Download failed with HTTP status \(httpResponse.statusCode)."
            )
            NSLog("%@", formatMessage("Download failed with HTTP status \(httpResponse.statusCode)"))
            failCallback?(error)
            return
        }
        
        // Check MIME type if specified. For HTTP, use the Content-Type header, since URLResponse.mimeType
        // is sniffed from the content when the header is missing; a missing header fails, as on Android.
        let responseMimeType = (downloadTask.response as? HTTPURLResponse).map { $0.value(forHTTPHeaderField: "Content-Type") }
            ?? downloadTask.response?.mimeType
        if let expectedMimeType = mimeType,
           !mimeTypeMatches(responseMimeType, expected: expectedMimeType) {
            failCallback?(NativeDownloadError(code: NativeDownloadError.ERROR_DOWNLOAD_FAILED, message: "MIME type not expected."))
            return
        }
        
        // Check if file already exists
        if fileManager.fileExists(atPath: downloadPath) {
            failCallback?(NativeDownloadError(code: NativeDownloadError.FILE_ALREADY_EXISTS, message: "File already exists in the same path."))
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
            failCallback?(NativeDownloadError.fileSystem(error, message: "Could not create path: \(error.localizedDescription)"))
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
            failCallback?(NativeDownloadError.fileSystem(error, message: "Could not copy path: \(error.localizedDescription)"))
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
    
    public func download(
        _ url: String,
        downloadPath: String,
        connectionTimeout: NSNumber?,
        mimeType: String?,
        onProgress: (([String: Int64]) -> Void)?,
        promise: Promise
    ) {
        
        let handler = NativeDownloadHandler(
            connectionTimeout: connectionTimeout,
            mimeType: mimeType,
            doneCallback: {
                promise.resolve(nil)
            },
            progressCallback: { received, total in
                onProgress?(["receivedBytes": received, "totalBytes": total])
            },
            failCallback: { error in
                promise.reject(NativeDownloadError.code(for: error), formatMessage(error.localizedDescription), error)
            }
        )
        
        handler.download(url, downloadPath: downloadPath)
    }
}
