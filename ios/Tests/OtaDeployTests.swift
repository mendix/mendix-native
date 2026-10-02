import XCTest
import SSZipArchive
@testable import MendixNative

final class OtaDeployTests: XCTestCase {

    private var otaDir: String { OtaHelpers.getOtaDir() }
    private var module: NativeOtaModule!

    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(atPath: otaDir)
        // init creates the OTA directory.
        module = NativeOtaModule()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: otaDir)
        super.tearDown()
    }

    // MARK: - Helpers

    private enum Outcome {
        case resolved
        case rejected(code: String?)
    }

    private func deploy(id: String, package: String, extractionDir: String) -> Outcome {
        var outcome: Outcome?
        let promise = Promise(
            resolve: { _ in outcome = .resolved },
            reject: { code, _, _ in outcome = .rejected(code: code) }
        )
        module.deploy(OtaDeploymentConfiguration(otaDeploymentID: id, otaPackage: package, extractionDir: extractionDir), promise: promise)
        // deploy settles synchronously.
        return outcome!
    }

    /// Writes a zip containing index.ios.bundle into the OTA dir and returns its file name.
    @discardableResult
    private func makeOtaPackage(_ name: String, bundleContent: String = "bundle") throws -> String {
        let staging = NSTemporaryDirectory() + UUID().uuidString
        try FileManager.default.createDirectory(atPath: staging, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: staging) }
        try bundleContent.write(toFile: "\(staging)/index.ios.bundle", atomically: true, encoding: .utf8)

        let zipPath = "\(otaDir)/\(name)"
        XCTAssertTrue(SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: staging))
        return name
    }

    private func path(_ relative: String) -> String {
        OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(relative)")
    }

    /// A directory next to the OTA dir that deploys must never touch.
    private func makeSentinel() throws -> String {
        let sentinel = ((otaDir as NSString).deletingLastPathComponent as NSString).appendingPathComponent("sentinel")
        try? FileManager.default.removeItem(atPath: sentinel)
        try FileManager.default.createDirectory(atPath: sentinel, withIntermediateDirectories: true)
        try "keep".write(toFile: "\(sentinel)/keep.txt", atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(atPath: sentinel) }
        return sentinel
    }

    private func setManifestBundlePath(_ relativeBundlePath: String) throws {
        var manifest = try XCTUnwrap(OtaHelpers.readManifestAsDictionary())
        manifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY] = relativeBundlePath
        try JSONSerialization.data(withJSONObject: manifest).write(to: URL(fileURLWithPath: OtaHelpers.getOtaManifestFilepath()))
    }

    private func assertResolved(_ outcome: Outcome, file: StaticString = #filePath, line: UInt = #line) {
        guard case .resolved = outcome else {
            return XCTFail("Expected deploy to resolve, got \(outcome)", file: file, line: line)
        }
    }

    private func assertRejected(_ outcome: Outcome, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        guard case .rejected(let code) = outcome else {
            return XCTFail("Expected rejection with \(expected), got resolve", file: file, line: line)
        }
        XCTAssertEqual(code, expected, file: file, line: line)
    }

    // MARK: - Tests

    func testDeployExtractsBundleWritesManifestAndRemovesZip() throws {
        let zip = try makeOtaPackage("first.zip", bundleContent: "first")

        guard case .resolved = deploy(id: "1", package: zip, extractionDir: "deployment-1") else {
            return XCTFail("Expected deploy to resolve")
        }

        XCTAssertEqual(try String(contentsOfFile: path("deployment-1/index.ios.bundle"), encoding: .utf8), "first")
        XCTAssertFalse(FileManager.default.fileExists(atPath: path(zip)))

        let manifest = try XCTUnwrap(OtaHelpers.readManifestAsDictionary())
        XCTAssertEqual(manifest[MANIFEST_OTA_DEPLOYMENT_ID_KEY] as? String, "1")
        XCTAssertEqual(manifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY] as? String, "deployment-1/index.ios.bundle")
        XCTAssertEqual(manifest[MANIFEST_APP_VERSION_KEY] as? String, OtaHelpers.resolveAppVersion())

        XCTAssertEqual(OtaJSBundleFileProvider.getBundleUrl()?.path, path("deployment-1/index.ios.bundle"))
    }

    func testNewDeploymentRemovesPreviousBundle() throws {
        guard case .resolved = deploy(id: "1", package: try makeOtaPackage("first.zip"), extractionDir: "deployment-1"),
              case .resolved = deploy(id: "2", package: try makeOtaPackage("second.zip"), extractionDir: "deployment-2") else {
            return XCTFail("Expected both deploys to resolve")
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: path("deployment-1")))
        XCTAssertTrue(FileManager.default.fileExists(atPath: path("deployment-2/index.ios.bundle")))
        XCTAssertEqual(OtaJSBundleFileProvider.getBundleUrl()?.path, path("deployment-2/index.ios.bundle"))
    }

    func testRedeployingActiveDeploymentIsRejectedAndKeepsBundle() throws {
        guard case .resolved = deploy(id: "1", package: try makeOtaPackage("first.zip"), extractionDir: "deployment-1") else {
            return XCTFail("Expected first deploy to resolve")
        }
        let zip = try makeOtaPackage("again.zip")

        assertRejected(deploy(id: "1", package: zip, extractionDir: "deployment-1"), OTA_ALREADY_DEPLOYED)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path(zip)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: path("deployment-1/index.ios.bundle")))
    }

    func testRedeployingSameIdIsAllowedWhenBundleIsMissing() throws {
        guard case .resolved = deploy(id: "1", package: try makeOtaPackage("first.zip"), extractionDir: "deployment-1") else {
            return XCTFail("Expected first deploy to resolve")
        }
        try FileManager.default.removeItem(atPath: path("deployment-1"))

        guard case .resolved = deploy(id: "1", package: try makeOtaPackage("again.zip"), extractionDir: "deployment-1") else {
            return XCTFail("Expected redeploy to resolve")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: path("deployment-1/index.ios.bundle")))
    }

    func testMissingConfigKeysAreRejectedWithDeployConfigCode() {
        let configs = [
            OtaDeploymentConfiguration(otaDeploymentID: nil, otaPackage: "first.zip", extractionDir: "deployment-1"),
            OtaDeploymentConfiguration(otaDeploymentID: "1", otaPackage: nil, extractionDir: "deployment-1"),
            OtaDeploymentConfiguration(otaDeploymentID: "1", otaPackage: "first.zip", extractionDir: nil),
        ]
        for config in configs {
            var outcome: Outcome?
            let promise = Promise(
                resolve: { _ in outcome = .resolved },
                reject: { code, _, _ in outcome = .rejected(code: code) }
            )
            module.deploy(config, promise: promise)
            assertRejected(try! XCTUnwrap(outcome), INVALID_DEPLOY_CONFIG)
        }
    }

    func testMissingPackageIsRejected() {
        assertRejected(deploy(id: "1", package: "missing.zip", extractionDir: "deployment-1"), OTA_ZIP_FILE_MISSING)
        XCTAssertNil(OtaJSBundleFileProvider.getBundleUrl())
    }

    func testInvalidZipIsRejectedAndRemoved() throws {
        try "not a zip".write(toFile: path("invalid.zip"), atomically: true, encoding: .utf8)

        assertRejected(deploy(id: "1", package: "invalid.zip", extractionDir: "deployment-1"), OTA_DEPLOYMENT_FAILED)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path("invalid.zip")))
        XCTAssertNil(OtaHelpers.readManifestAsDictionary())
    }

    func testBundleUrlIsNilWhenAppVersionChanged() throws {
        guard case .resolved = deploy(id: "1", package: try makeOtaPackage("first.zip"), extractionDir: "deployment-1") else {
            return XCTFail("Expected deploy to resolve")
        }
        var manifest = try XCTUnwrap(OtaHelpers.readManifestAsDictionary())
        manifest[MANIFEST_APP_VERSION_KEY] = "0.0.0-0"
        try JSONSerialization.data(withJSONObject: manifest).write(to: URL(fileURLWithPath: OtaHelpers.getOtaManifestFilepath()))

        XCTAssertNil(OtaJSBundleFileProvider.getBundleUrl())
    }

    func testBundleUrlIsNilWithoutManifest() {
        XCTAssertNil(OtaJSBundleFileProvider.getBundleUrl())
    }

    func testExtractionDirOutsideOtaDirIsRejected() throws {
        let sentinel = try makeSentinel()

        for extractionDir in ["../sentinel", "deployment-1/../../sentinel", "", ".", "deployment-1/.."] {
            let zip = try makeOtaPackage("first.zip")
            assertRejected(deploy(id: "1", package: zip, extractionDir: extractionDir), INVALID_DEPLOY_CONFIG)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path(zip)), extractionDir)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: otaDir))
        XCTAssertNil(OtaHelpers.readManifestAsDictionary())
        XCTAssertEqual(try String(contentsOfFile: "\(sentinel)/keep.txt", encoding: .utf8), "keep")
    }

    func testOtaPackageOutsideOtaDirIsRejected() throws {
        let outsideZip = ((otaDir as NSString).deletingLastPathComponent as NSString).appendingPathComponent("outside.zip")
        try FileManager.default.moveItem(atPath: path(try makeOtaPackage("outside.zip")), toPath: outsideZip)
        defer { try? FileManager.default.removeItem(atPath: outsideZip) }

        assertRejected(deploy(id: "1", package: "../outside.zip", extractionDir: "deployment-1"), INVALID_DEPLOY_CONFIG)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outsideZip))
        XCTAssertFalse(FileManager.default.fileExists(atPath: path("deployment-1")))
    }

    func testExtractionDirInSubdirectoryIsAllowed() throws {
        assertResolved(deploy(id: "1", package: try makeOtaPackage("first.zip"), extractionDir: "deployments/1"))

        let manifest = try XCTUnwrap(OtaHelpers.readManifestAsDictionary())
        XCTAssertEqual(manifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY] as? String, "deployments/1/index.ios.bundle")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path("deployments/1/index.ios.bundle")))
    }

    func testOldBundleOutsideOtaDirIsNotRemoved() throws {
        let sentinel = try makeSentinel()
        assertResolved(deploy(id: "1", package: try makeOtaPackage("first.zip"), extractionDir: "deployment-1"))
        try setManifestBundlePath("../sentinel/index.ios.bundle")

        assertResolved(deploy(id: "2", package: try makeOtaPackage("second.zip"), extractionDir: "deployment-2"))
        XCTAssertEqual(try String(contentsOfFile: "\(sentinel)/keep.txt", encoding: .utf8), "keep")
    }

    func testOldBundleInOtaDirRootDoesNotRemoveOtaDir() throws {
        assertResolved(deploy(id: "1", package: try makeOtaPackage("first.zip"), extractionDir: "deployment-1"))
        try setManifestBundlePath("index.ios.bundle")

        assertResolved(deploy(id: "2", package: try makeOtaPackage("second.zip"), extractionDir: "deployment-2"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: path("deployment-2/index.ios.bundle")))
        XCTAssertNotNil(OtaHelpers.readManifestAsDictionary())
    }

    func testNewDeploymentIntoSameDirKeepsNewBundle() throws {
        assertResolved(deploy(id: "1", package: try makeOtaPackage("first.zip", bundleContent: "first"), extractionDir: "deployment"))
        assertResolved(deploy(id: "2", package: try makeOtaPackage("second.zip", bundleContent: "second"), extractionDir: "deployment"))

        XCTAssertEqual(try String(contentsOfFile: path("deployment/index.ios.bundle"), encoding: .utf8), "second")
    }
}
