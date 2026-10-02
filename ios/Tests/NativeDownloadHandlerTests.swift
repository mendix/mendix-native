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
}
