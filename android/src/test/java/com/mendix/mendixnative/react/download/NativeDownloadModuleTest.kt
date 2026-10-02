package com.mendix.mendixnative.react.download

import com.facebook.react.bridge.BridgeReactContext
import com.facebook.react.bridge.JavaOnlyMap
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.WritableMap
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.SocketPolicy
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import java.io.File
import java.io.IOException
import java.net.ConnectException
import java.net.SocketTimeoutException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
class NativeDownloadModuleTest {
  @get:Rule
  val tempFolder = TemporaryFolder()

  private lateinit var server: MockWebServer
  private lateinit var module: NativeDownloadModule

  @Before
  fun setUp() {
    server = MockWebServer().apply { start() }
    module = NativeDownloadModule(BridgeReactContext(RuntimeEnvironment.getApplication()))
  }

  @After
  fun tearDown() {
    server.shutdown()
  }

  private sealed class Outcome {
    object Resolved : Outcome()
    data class Rejected(val code: String?) : Outcome()
  }

  private class RecordingPromise : Promise {
    val latch = CountDownLatch(1)
    var outcome: Outcome? = null

    private fun settle(value: Outcome) {
      outcome = value
      latch.countDown()
    }

    override fun resolve(value: Any?) = settle(Outcome.Resolved)
    override fun reject(code: String?, message: String?) = settle(Outcome.Rejected(code))
    override fun reject(code: String?, throwable: Throwable?) = settle(Outcome.Rejected(code))
    override fun reject(code: String?, message: String?, throwable: Throwable?) = settle(Outcome.Rejected(code))
    override fun reject(throwable: Throwable) = settle(Outcome.Rejected(null))
    override fun reject(throwable: Throwable, userInfo: WritableMap) = settle(Outcome.Rejected(null))
    override fun reject(code: String?, userInfo: WritableMap) = settle(Outcome.Rejected(code))
    override fun reject(code: String?, throwable: Throwable?, userInfo: WritableMap) = settle(Outcome.Rejected(code))
    override fun reject(code: String?, message: String?, userInfo: WritableMap) = settle(Outcome.Rejected(code))
    override fun reject(code: String?, message: String?, throwable: Throwable?, userInfo: WritableMap?) =
      settle(Outcome.Rejected(code))

    @Deprecated("Deprecated in Java")
    override fun reject(message: String) = settle(Outcome.Rejected(null))
  }

  private fun download(url: String, file: File, mimeType: String? = null): Outcome {
    val promise = RecordingPromise()
    val config = JavaOnlyMap().apply { mimeType?.let { putString("mimeType", it) } }
    module.download(url, file.absolutePath, config, promise)
    assertTrue("download did not settle", promise.latch.await(5, TimeUnit.SECONDS))
    return promise.outcome!!
  }

  private fun file(name: String) = File(tempFolder.root, name)

  @Test
  fun successResolves() {
    server.enqueue(MockResponse().setBody("content"))

    assertEquals(Outcome.Resolved, download(server.url("/file").toString(), file("file.txt")))
  }

  @Test
  fun errorStatusRejectsWithDownloadFailed() {
    server.enqueue(MockResponse().setResponseCode(404))

    assertEquals(
      Outcome.Rejected(NativeDownloadModule.ERROR_DOWNLOAD_FAILED),
      download(server.url("/file").toString(), file("file.txt"))
    )
  }

  @Test
  fun existingDestinationRejectsWithFileAlreadyExists() {
    val existing = tempFolder.newFile("existing.txt").apply { writeText("keep") }

    assertEquals(
      Outcome.Rejected(NativeDownloadModule.FILE_ALREADY_EXISTS),
      download(server.url("/file").toString(), existing)
    )
    assertEquals("keep", existing.readText())
    assertEquals(0, server.requestCount)
  }

  @Test
  fun invalidUrlRejectsInsteadOfThrowing() {
    val destination = file("file.txt")

    assertEquals(
      Outcome.Rejected(NativeDownloadModule.ERROR_DOWNLOAD_FAILED),
      download("://invalid", destination)
    )
    assertFalse(destination.exists())
  }

  @Test
  fun connectionFailureRejectsWithDownloadFailed() {
    val url = server.url("/file").toString()
    server.shutdown()

    assertEquals(Outcome.Rejected(NativeDownloadModule.ERROR_DOWNLOAD_FAILED), download(url, file("file.txt")))
  }

  @Test
  fun disconnectBeforeResponseRejectsWithDownloadFailed() {
    server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.DISCONNECT_AT_START))

    assertEquals(
      Outcome.Rejected(NativeDownloadModule.ERROR_DOWNLOAD_FAILED),
      download(server.url("/file").toString(), file("file.txt"))
    )
  }

  @Test
  fun disconnectDuringBodyRejectsWithDownloadFailedAndRemovesFile() {
    server.enqueue(
      MockResponse().setBody("x".repeat(256 * 1024)).setSocketPolicy(SocketPolicy.DISCONNECT_DURING_RESPONSE_BODY)
    )
    val destination = file("file.txt")

    assertEquals(
      Outcome.Rejected(NativeDownloadModule.ERROR_DOWNLOAD_FAILED),
      download(server.url("/file").toString(), destination)
    )
    assertFalse(destination.exists())
  }

  @Test
  fun unwritableDestinationRejectsWithIoException() {
    // The parent is a file, so the destination can't be created.
    val parent = tempFolder.newFile("not-a-dir")

    assertEquals(
      Outcome.Rejected(NativeDownloadModule.IO_EXCEPTION),
      download(server.url("/file").toString(), File(parent, "file.txt"))
    )
    assertEquals(0, server.requestCount)
  }

  @Test
  fun mimeTypeWithCharsetResolves() {
    server.enqueue(MockResponse().setHeader("Content-Type", "text/plain; charset=utf-8").setBody("content"))

    assertEquals(Outcome.Resolved, download(server.url("/file").toString(), file("file.txt"), "text/plain"))
  }

  @Test
  fun mismatchingMimeTypeRejectsWithDownloadFailed() {
    server.enqueue(MockResponse().setHeader("Content-Type", "text/plain").setBody("content"))

    assertEquals(
      Outcome.Rejected(NativeDownloadModule.ERROR_DOWNLOAD_FAILED),
      download(server.url("/file").toString(), file("file.zip"), "application/zip")
    )
  }

  @Test
  fun errorsMapToCodes() {
    assertEquals(NativeDownloadModule.FILE_ALREADY_EXISTS, downloadErrorFor(FileAlreadyExistsException(file("x"))).first)
    assertEquals(NativeDownloadModule.ERROR_DOWNLOAD_FAILED, downloadErrorFor(HttpStatusException(500)).first)
    assertEquals(NativeDownloadModule.ERROR_DOWNLOAD_FAILED, downloadErrorFor(ConnectException()).first)
    assertEquals(NativeDownloadModule.ERROR_DOWNLOAD_FAILED, downloadErrorFor(DownloadMimeTypeException()).first)
    assertEquals(NativeDownloadModule.ERROR_CONNECTION_FAILED, downloadErrorFor(NoDataException()).first)
    assertEquals(NativeDownloadModule.IO_EXCEPTION, downloadErrorFor(FileCorruptionException()).first)
    assertEquals(NativeDownloadModule.IO_EXCEPTION, downloadErrorFor(DownloadFileException(IOException())).first)
    // Any other IOException comes from the network, as on iOS.
    assertEquals(NativeDownloadModule.ERROR_DOWNLOAD_FAILED, downloadErrorFor(IOException()).first)
    assertEquals(NativeDownloadModule.ERROR_DOWNLOAD_FAILED, downloadErrorFor(SocketTimeoutException()).first)
    assertEquals(NativeDownloadModule.FS_ACCESS_EXCEPTION, downloadErrorFor(SecurityException()).first)
    assertEquals(NativeDownloadModule.ERROR_DOWNLOAD_FAILED, downloadErrorFor(IllegalArgumentException()).first)
  }
}
