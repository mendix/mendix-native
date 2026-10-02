package com.mendix.mendixnative.react.ota

import android.content.Context
import com.facebook.react.bridge.JavaOnlyMap
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.BridgeReactContext
import com.facebook.react.bridge.WritableMap
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

@RunWith(RobolectricTestRunner::class)
class NativeOtaModuleTest {
  private lateinit var context: Context
  private lateinit var module: NativeOtaModule
  private lateinit var otaDir: File

  @Before
  fun setUp() {
    context = RuntimeEnvironment.getApplication()
    otaDir = File(getOtaDir(context)).apply { deleteRecursively() }
    module = NativeOtaModule(BridgeReactContext(context))
  }

  @After
  fun tearDown() {
    otaDir.deleteRecursively()
  }

  private sealed class Outcome {
    object Resolved : Outcome()
    data class Rejected(val code: String?) : Outcome()
  }

  private class RecordingPromise : Promise {
    var outcome: Outcome? = null
    override fun resolve(value: Any?) { outcome = Outcome.Resolved }
    override fun reject(code: String?, message: String?) { outcome = Outcome.Rejected(code) }
    override fun reject(code: String?, throwable: Throwable?) { outcome = Outcome.Rejected(code) }
    override fun reject(code: String?, message: String?, throwable: Throwable?) { outcome = Outcome.Rejected(code) }
    override fun reject(throwable: Throwable) { outcome = Outcome.Rejected(null) }
    override fun reject(throwable: Throwable, userInfo: WritableMap) { outcome = Outcome.Rejected(null) }
    override fun reject(code: String?, userInfo: WritableMap) { outcome = Outcome.Rejected(code) }
    override fun reject(code: String?, throwable: Throwable?, userInfo: WritableMap) { outcome = Outcome.Rejected(code) }
    override fun reject(code: String?, message: String?, userInfo: WritableMap) { outcome = Outcome.Rejected(code) }
    override fun reject(code: String?, message: String?, throwable: Throwable?, userInfo: WritableMap?) { outcome = Outcome.Rejected(code) }
    @Deprecated("Deprecated in Java")
    override fun reject(message: String) { outcome = Outcome.Rejected(null) }
  }

  private fun deploy(id: String, pkg: String, extractionDir: String): Outcome {
    val promise = RecordingPromise()
    module.deploy(
      JavaOnlyMap.of("otaDeploymentID", id, "otaPackage", pkg, "extractionDir", extractionDir),
      promise
    )
    // deploy settles synchronously.
    return promise.outcome!!
  }

  /** Writes a zip containing index.android.bundle into the OTA dir and returns its file name. */
  private fun makeOtaPackage(name: String, bundleContent: String = "bundle"): String =
    makeZip(name, mapOf("index.android.bundle" to bundleContent))

  /** Writes a zip with the given entries (a null content makes a directory entry) into the OTA dir. */
  private fun makeZip(name: String, entries: Map<String, String?>): String {
    ZipOutputStream(File(otaDir, name).outputStream()).use { zip ->
      entries.forEach { (entryName, content) ->
        zip.putNextEntry(ZipEntry(entryName))
        content?.let { zip.write(it.toByteArray()) }
        zip.closeEntry()
      }
    }
    return name
  }

  /** A directory next to the OTA dir that deploys must never touch. */
  private fun makeSentinel(): File =
    File(otaDir.parentFile, "sentinel").apply {
      deleteRecursively()
      mkdirs()
      File(this, "keep.txt").writeText("keep")
    }

  private fun assertSentinelIntact(sentinel: File) {
    assertEquals("keep", File(sentinel, "keep.txt").readText())
    sentinel.deleteRecursively()
  }

  private fun file(relative: String) = File(otaDir, relative)

  @Test
  fun deployExtractsBundleWritesManifestAndRemovesZip() {
    val zip = makeOtaPackage("first.zip", "first")

    assertEquals(Outcome.Resolved, deploy("1", zip, "deployment-1"))

    assertEquals("first", file("deployment-1/index.android.bundle").readText())
    assertFalse(file(zip).exists())
    val manifest = JSONObject(File(getOtaManifestFilepath(context)).readText())
    assertEquals("1", manifest.getString(MANIFEST_OTA_DEPLOYMENT_ID_KEY))
    assertEquals("deployment-1/index.android.bundle", manifest.getString(MANIFEST_RELATIVE_BUNDLE_PATH_KEY))
    assertEquals(resolveAppVersion(context), manifest.getString(MANIFEST_APP_VERSION_KEY))

    assertEquals(
      file("deployment-1/index.android.bundle").absolutePath,
      OtaJSBundleUrlProvider().getJSBundleFile(context)
    )
  }

  @Test
  fun newDeploymentRemovesPreviousBundle() {
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip"), "deployment-1"))
    assertEquals(Outcome.Resolved, deploy("2", makeOtaPackage("second.zip"), "deployment-2"))

    assertFalse(file("deployment-1").exists())
    assertEquals(
      file("deployment-2/index.android.bundle").absolutePath,
      OtaJSBundleUrlProvider().getJSBundleFile(context)
    )
  }

  @Test
  fun redeployingActiveDeploymentIsRejectedAndKeepsBundle() {
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip"), "deployment-1"))
    val zip = makeOtaPackage("again.zip")

    assertEquals(Outcome.Rejected(OTA_ALREADY_DEPLOYED), deploy("1", zip, "deployment-1"))
    assertFalse(file(zip).exists())
    assertTrue(file("deployment-1/index.android.bundle").exists())
  }

  @Test
  fun redeployingSameIdIsAllowedWhenBundleIsMissing() {
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip"), "deployment-1"))
    file("deployment-1").deleteRecursively()

    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("again.zip"), "deployment-1"))
    assertTrue(file("deployment-1/index.android.bundle").exists())
  }

  @Test
  fun missingPackageIsRejected() {
    assertEquals(Outcome.Rejected(OTA_ZIP_FILE_MISSING), deploy("1", "missing.zip", "deployment-1"))
    assertNull(OtaJSBundleUrlProvider().getJSBundleFile(context))
  }

  @Test
  fun invalidZipIsRejectedWithoutManifest() {
    file("invalid.zip").writeText("not a zip")

    assertEquals(Outcome.Rejected(OTA_DEPLOYMENT_FAILED), deploy("1", "invalid.zip", "deployment-1"))
    assertFalse(file("deployment-1").exists())
    assertFalse(File(getOtaManifestFilepath(context)).exists())
  }

  @Test
  fun missingConfigKeyIsRejected() {
    val promise = RecordingPromise()
    module.deploy(JavaOnlyMap.of("otaPackage", "first.zip", "extractionDir", "deployment-1"), promise)

    assertEquals(Outcome.Rejected(INVALID_DEPLOY_CONFIG), promise.outcome)
  }

  @Test
  fun bundleIsIgnoredWhenAppVersionChanged() {
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip"), "deployment-1"))
    val manifestFile = File(getOtaManifestFilepath(context))
    manifestFile.writeText(JSONObject(manifestFile.readText()).put(MANIFEST_APP_VERSION_KEY, "0.0.0-0").toString())

    assertNull(OtaJSBundleUrlProvider().getJSBundleFile(context))
  }

  @Test
  fun zipWithEntryOutsideExtractionDirIsRejected() {
    val zip = makeZip(
      "slip.zip",
      mapOf("index.android.bundle" to "bundle", "../escape.txt" to "escaped", "../../escape.txt" to "escaped")
    )

    assertEquals(Outcome.Rejected(OTA_DEPLOYMENT_FAILED), deploy("1", zip, "deployment-1"))
    assertFalse(file("escape.txt").exists())
    assertFalse(File(otaDir.parentFile, "escape.txt").exists())
    assertFalse(file("deployment-1").exists())
    assertFalse(File(getOtaManifestFilepath(context)).exists())
  }

  @Test
  fun zipWithNestedAndEmptyDirectoriesIsExtracted() {
    val zip = makeZip(
      "nested.zip",
      mapOf(
        "index.android.bundle" to "bundle",
        "assets/a/b/image.png" to "image",
        "empty/" to null,
        "./dot.txt" to "dot",
      )
    )

    assertEquals(Outcome.Resolved, deploy("1", zip, "deployment-1"))
    assertEquals("image", file("deployment-1/assets/a/b/image.png").readText())
    assertEquals("dot", file("deployment-1/dot.txt").readText())
    assertTrue(file("deployment-1/empty").isDirectory)
  }

  @Test
  fun extractionDirOutsideOtaDirIsRejected() {
    val sentinel = makeSentinel()

    for (extractionDir in listOf("../sentinel", "deployment-1/../../sentinel", "", ".", "deployment-1/..")) {
      val zip = makeOtaPackage("first.zip")
      assertEquals(extractionDir, Outcome.Rejected(INVALID_DEPLOY_CONFIG), deploy("1", zip, extractionDir))
      assertTrue(file(zip).exists())
    }
    assertTrue(otaDir.exists())
    assertFalse(File(getOtaManifestFilepath(context)).exists())
    assertSentinelIntact(sentinel)
  }

  @Test
  fun otaPackageOutsideOtaDirIsRejected() {
    val outsideZip = File(otaDir.parentFile, "outside.zip")
    makeOtaPackage("outside.zip")
    file("outside.zip").renameTo(outsideZip)

    assertEquals(Outcome.Rejected(INVALID_DEPLOY_CONFIG), deploy("1", "../outside.zip", "deployment-1"))
    assertTrue(outsideZip.exists())
    assertFalse(file("deployment-1").exists())
    outsideZip.delete()
  }

  @Test
  fun extractionDirInSubdirectoryIsAllowed() {
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip"), "deployments/1"))

    val manifest = JSONObject(File(getOtaManifestFilepath(context)).readText())
    assertEquals("deployments/1/index.android.bundle", manifest.getString(MANIFEST_RELATIVE_BUNDLE_PATH_KEY))
  }

  @Test
  fun oldBundleOutsideOtaDirIsNotRemoved() {
    val sentinel = makeSentinel()
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip"), "deployment-1"))
    val manifestFile = File(getOtaManifestFilepath(context))
    manifestFile.writeText(
      JSONObject(manifestFile.readText())
        .put(MANIFEST_RELATIVE_BUNDLE_PATH_KEY, "../sentinel/index.android.bundle").toString()
    )

    assertEquals(Outcome.Resolved, deploy("2", makeOtaPackage("second.zip"), "deployment-2"))
    assertSentinelIntact(sentinel)
  }

  @Test
  fun oldBundleInOtaDirRootDoesNotRemoveOtaDir() {
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip"), "deployment-1"))
    val manifestFile = File(getOtaManifestFilepath(context))
    manifestFile.writeText(
      JSONObject(manifestFile.readText()).put(MANIFEST_RELATIVE_BUNDLE_PATH_KEY, "index.android.bundle").toString()
    )

    assertEquals(Outcome.Resolved, deploy("2", makeOtaPackage("second.zip"), "deployment-2"))
    assertTrue(file("deployment-2/index.android.bundle").exists())
    assertTrue(manifestFile.exists())
  }

  @Test
  fun newDeploymentIntoSameDirKeepsNewBundle() {
    assertEquals(Outcome.Resolved, deploy("1", makeOtaPackage("first.zip", "first"), "deployment"))
    assertEquals(Outcome.Resolved, deploy("2", makeOtaPackage("second.zip", "second"), "deployment"))

    assertEquals("second", file("deployment/index.android.bundle").readText())
  }
}
