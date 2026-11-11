import XCTest
@testable import MendixNative

final class NativeFsPathTests: XCTestCase {

    private let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    private let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!

    func testAllowsPathsInsideAllowedRoots() {
        XCTAssertNoThrow(try NativeFsModule.ensureWhiteListedPath([
            documents,
            "\(documents)/file.json",
            "\(documents)/nested/dir/file.json",
            "\(caches)/file.json",
            NSTemporaryDirectory() + "file.json",
        ]))
    }

    func testAllowsNormalizedPathsThatStayInsideRoot() {
        XCTAssertNoThrow(try NativeFsModule.ensureWhiteListedPath(["\(documents)/a/../file.json"]))
    }

    func testRejectsTraversalOutOfRoot() {
        XCTAssertThrowsError(try NativeFsModule.ensureWhiteListedPath(["\(documents)/../escape.json"]))
        XCTAssertThrowsError(try NativeFsModule.ensureWhiteListedPath(["\(documents)/a/../../escape.json"]))
    }

    func testRejectsSiblingWithRootPrefix() {
        XCTAssertThrowsError(try NativeFsModule.ensureWhiteListedPath(["\(documents)Evil/file.json"]))
    }

    func testRejectsRelativeAndUnrelatedPaths() {
        XCTAssertThrowsError(try NativeFsModule.ensureWhiteListedPath(["file.json"]))
        XCTAssertThrowsError(try NativeFsModule.ensureWhiteListedPath(["/etc/hosts"]))
    }

    func testRejectsWhenAnyPathIsOutsideRoot() {
        XCTAssertThrowsError(try NativeFsModule.ensureWhiteListedPath(["\(documents)/ok.json", "/etc/hosts"]))
    }
}
