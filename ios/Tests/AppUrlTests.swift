import XCTest
@testable import MendixNative

final class AppUrlTests: XCTestCase {

    func testForRuntimeAddsProtocolAndTrailingSlash() {
        XCTAssertEqual(AppUrl.forRuntime("example.com").absoluteString, "http://example.com/")
        XCTAssertEqual(AppUrl.forRuntime("https://example.com/").absoluteString, "https://example.com/")
    }

    func testForRuntimeKeepsSubpath() {
        XCTAssertEqual(AppUrl.forRuntime("https://example.com/app").absoluteString, "https://example.com/app/")
    }

    func testForBundleUsesPortAndDevModeQuery() {
        let url = AppUrl.forBundle("localhost", port: 8081, isDebuggingRemotely: false, isDevModeEnabled: true)
        XCTAssertEqual(url.absoluteString, "http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false")
    }

    func testForBundleUsesProductionQuery() {
        let url = AppUrl.forBundle("localhost", port: 8081, isDebuggingRemotely: false, isDevModeEnabled: false)
        XCTAssertEqual(url.absoluteString, "http://localhost:8081/index.bundle?platform=ios&dev=false&minify=true")
    }

    func testForBundleFallsBackToDefaultPackagerPort() {
        let url = AppUrl.forBundle("localhost", port: 0, isDebuggingRemotely: false, isDevModeEnabled: true)
        XCTAssertEqual(url.port, AppUrl.defaultPackagerPort)
    }

    func testForPackagerStatus() {
        XCTAssertEqual(AppUrl.forPackagerStatus("localhost/", port: 8081)?.absoluteString, "http://localhost:8081/status")
    }

    func testForRuntimeInfo() {
        XCTAssertEqual(AppUrl.forRuntimeInfo("https://example.com")?.absoluteString, "https://example.com/xas/")
    }

    func testIsValid() {
        XCTAssertTrue(AppUrl.isValid("example.com"))
        XCTAssertTrue(AppUrl.isValid("https://example.com/"))
        XCTAssertTrue(AppUrl.isValid("  http://10.0.0.1:8080  "))
        XCTAssertFalse(AppUrl.isValid(""))
        XCTAssertFalse(AppUrl.isValid("   "))
        XCTAssertFalse(AppUrl.isValid("https://example.com/app"))
        XCTAssertFalse(AppUrl.isValid("https://example.com?debug=true"))
    }
}
