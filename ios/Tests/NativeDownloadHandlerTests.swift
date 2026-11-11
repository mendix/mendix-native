import XCTest
@testable import MendixNative

final class NativeDownloadHandlerTests: XCTestCase {

    private var workDir: String!

    override func setUpWithError() throws {
        workDir = NSTemporaryDirectory() + UUID().uuidString
        try FileManager.default.createDirectory(atPath: workDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: workDir)
        super.tearDown()
    }

    /// Starts a download, waits for its callback, and returns the handler weakly.
    private func download(_ url: String, to destination: String, succeeds: Bool) -> NativeDownloadHandler? {
        let finished = expectation(description: "download finished")
        weak var weakHandler: NativeDownloadHandler?
        // The handler is only referenced locally, as in NativeDownloadModule.
        autoreleasepool {
            let handler = NativeDownloadHandler(
                connectionTimeout: nil,
                mimeType: nil,
                doneCallback: {
                    XCTAssertTrue(succeeds, "Expected the download to fail")
                    finished.fulfill()
                },
                progressCallback: nil,
                failCallback: { error in
                    XCTAssertFalse(succeeds, "Unexpected failure: \(error)")
                    finished.fulfill()
                }
            )
            weakHandler = handler
            handler.download(url, downloadPath: destination)
        }
        wait(for: [finished], timeout: 5)
        return weakHandler
    }

    /// The session releases its delegate shortly after the completion callback.
    private func assertReleased(_ handler: @autoclosure () -> NativeDownloadHandler?, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(2)
        while handler() != nil && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertNil(handler(), "The download handler leaked", file: file, line: line)
    }

    func testHandlerIsReleasedAfterSuccessfulDownload() throws {
        let source = "\(workDir!)/source.txt"
        try "content".write(toFile: source, atomically: true, encoding: .utf8)
        let destination = "\(workDir!)/nested/destination.txt"

        weak var handler = download(URL(fileURLWithPath: source).absoluteString, to: destination, succeeds: true)

        XCTAssertEqual(try String(contentsOfFile: destination, encoding: .utf8), "content")
        assertReleased(handler)
    }

    func testHandlerIsReleasedAfterFailedDownload() {
        weak var handler = download(
            URL(fileURLWithPath: "\(workDir!)/missing.txt").absoluteString,
            to: "\(workDir!)/destination.txt",
            succeeds: false
        )

        assertReleased(handler)
    }

    func testHandlerIsReleasedAfterInvalidUrl() {
        weak var handler = download("://invalid url", to: "\(workDir!)/destination.txt", succeeds: false)

        assertReleased(handler)
    }

    // MARK: - Behaviour shared with Android

    /// Downloads through NativeDownloadModule and returns the rejection code, or nil when it resolved.
    private func rejectionCode(_ url: String, to destination: String, mimeType: String? = nil) -> String? {
        let finished = expectation(description: "download settled")
        var code: String?
        let promise = Promise(
            resolve: { _ in finished.fulfill() },
            reject: { rejectCode, _, _ in code = rejectCode; finished.fulfill() }
        )
        NativeDownloadModule().download(url, downloadPath: destination, connectionTimeout: nil, mimeType: mimeType, onProgress: nil, promise: promise)
        wait(for: [finished], timeout: 5)
        return code
    }

    private func makeSource(_ content: String = "content") throws -> String {
        let source = "\(workDir!)/source.txt"
        try content.write(toFile: source, atomically: true, encoding: .utf8)
        return URL(fileURLWithPath: source).absoluteString
    }

    func testExistingDestinationIsRejectedBeforeDownloading() throws {
        let destination = "\(workDir!)/existing.txt"
        try "keep".write(toFile: destination, atomically: true, encoding: .utf8)
        // The source doesn't exist, so a started download would fail with a different code.
        let missingSource = URL(fileURLWithPath: "\(workDir!)/missing.txt").absoluteString

        XCTAssertEqual(rejectionCode(missingSource, to: destination), "FILE_ALREADY_EXISTS")
        XCTAssertEqual(try String(contentsOfFile: destination, encoding: .utf8), "keep")
    }

    func testFailedDownloadIsRejectedWithDownloadFailed() {
        let missingSource = URL(fileURLWithPath: "\(workDir!)/missing.txt").absoluteString

        XCTAssertEqual(rejectionCode(missingSource, to: "\(workDir!)/destination.txt"), "ERROR_DOWNLOAD_FAILED")
    }

    func testInvalidUrlIsRejectedWithDownloadFailed() {
        XCTAssertEqual(rejectionCode("://invalid url", to: "\(workDir!)/destination.txt"), "ERROR_DOWNLOAD_FAILED")
    }

    func testMimeTypeWithParametersIsAccepted() throws {
        let source = try makeSource()
        let destination = "\(workDir!)/destination.txt"

        XCTAssertNil(rejectionCode(source, to: destination, mimeType: "text/plain; charset=utf-8"))
        XCTAssertEqual(try String(contentsOfFile: destination, encoding: .utf8), "content")
    }

    func testMismatchingMimeTypeIsRejectedWithDownloadFailed() throws {
        let destination = "\(workDir!)/destination.zip"

        XCTAssertEqual(rejectionCode(try makeSource(), to: destination, mimeType: "application/zip"), "ERROR_DOWNLOAD_FAILED")
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination))
    }

    func testMimeTypeMatching() {
        XCTAssertTrue(mimeTypeMatches("text/plain", expected: "text/plain"))
        XCTAssertTrue(mimeTypeMatches("text/plain", expected: "Text/Plain; charset=utf-8"))
        XCTAssertTrue(mimeTypeMatches("TEXT/PLAIN; charset=utf-8", expected: "text/plain"))
        XCTAssertFalse(mimeTypeMatches("text/html", expected: "text/plain"))
        XCTAssertFalse(mimeTypeMatches(nil, expected: "text/plain"))
    }

    func testConnectionTimeoutKeepsSubSecondValues() {
        func handler(_ timeout: NSNumber?) -> NativeDownloadHandler {
            NativeDownloadHandler(connectionTimeout: timeout, mimeType: nil, doneCallback: {}, progressCallback: nil, failCallback: { _ in })
        }

        XCTAssertEqual(handler(500).connectionTimeout, 0.5)
        XCTAssertEqual(handler(2500).connectionTimeout, 2.5)
        XCTAssertEqual(handler(nil).connectionTimeout, 10)
    }

    func testFileSystemErrorsMapToCodes() {
        let permission = CocoaError(.fileWriteNoPermission)
        let other = CocoaError(.fileWriteOutOfSpace)

        XCTAssertEqual(NativeDownloadError.fileSystem(permission, message: "").code, "FS_ACCESS_EXCEPTION")
        XCTAssertEqual(NativeDownloadError.fileSystem(other, message: "").code, "IO_EXCEPTION")
        XCTAssertEqual(NativeDownloadError.code(for: URLError(.timedOut)), "ERROR_DOWNLOAD_FAILED")
    }
}
