package com.mendix.mendixnative.react.download

import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.net.ConnectException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class DownloadHelperTest {
  @get:Rule
  val tempFolder = TemporaryFolder()

  private lateinit var server: MockWebServer
  private val client = OkHttpClient()

  @Before
  fun setUp() {
    server = MockWebServer().apply { start() }
  }

  @After
  fun tearDown() {
    server.shutdown()
  }

  private class Result {
    val latch = CountDownLatch(1)
    var succeeded = false
    var error: Exception? = null

    fun await() = assertTrue("download did not finish", latch.await(5, TimeUnit.SECONDS))
  }

  private fun download(file: File, mimeType: String? = null): Result {
    val result = Result()
    downloadFile(
      client = client,
      url = server.url("/file").toString(),
      downloadPath = file.absolutePath,
      expectedMimeType = mimeType,
      onSuccess = { result.succeeded = true; result.latch.countDown() },
      onFailure = { result.error = it; result.latch.countDown() },
    )
    result.await()
    return result
  }

  @Test
  fun downloadsBodyToPathCreatingParentDirectories() {
    server.enqueue(MockResponse().setBody("content"))
    val file = File(tempFolder.root, "nested/dir/file.txt")

    val result = download(file)

    assertTrue(result.succeeded)
    assertEquals("content", file.readText())
  }

  @Test
  fun errorStatusFailsAndRemovesFile() {
    server.enqueue(MockResponse().setResponseCode(404).setBody("not found"))
    val file = File(tempFolder.root, "file.txt")

    val result = download(file)

    assertTrue(result.error is ConnectException)
    assertFalse(file.exists())
  }

  @Test
  fun mismatchingMimeTypeFailsAndRemovesFile() {
    server.enqueue(MockResponse().setHeader("Content-Type", "text/plain").setBody("content"))
    val file = File(tempFolder.root, "file.txt")

    val result = download(file, mimeType = "application/zip")

    assertTrue(result.error is DownloadMimeTypeException)
    assertFalse(file.exists())
  }

  @Test
  fun matchingMimeTypeSucceeds() {
    server.enqueue(MockResponse().setHeader("Content-Type", "application/zip").setBody("zip"))
    val file = File(tempFolder.root, "file.zip")

    val result = download(file, mimeType = "application/zip")

    assertNull(result.error)
    assertEquals("zip", file.readText())
  }

  @Test
  fun connectionFailureRemovesFile() {
    val file = File(tempFolder.root, "file.txt")
    server.shutdown()

    val result = Result()
    downloadFile(
      client = client,
      url = server.url("/file").toString(),
      downloadPath = file.absolutePath,
      onSuccess = { result.succeeded = true; result.latch.countDown() },
      onFailure = { result.error = it; result.latch.countDown() },
    )
    result.await()

    assertFalse(result.succeeded)
    assertFalse(file.exists())
  }

  @Test(expected = FileAlreadyExistsException::class)
  fun existingDestinationThrowsBeforeRequesting() {
    val file = tempFolder.newFile("existing.txt").apply { writeText("keep") }
    try {
      downloadFile(client, server.url("/file").toString(), file.absolutePath, {}, {})
    } finally {
      assertEquals("keep", file.readText())
      assertEquals(0, server.requestCount)
    }
  }

  @Test
  fun progressInvokerFiresOncePerInterval() {
    val calls = mutableListOf<Double>()
    val invoke = makeProgressCallbackInvoker(10.0) { received, _ -> calls.add(received) }

    listOf(1.0, 9.0, 10.0, 15.0, 19.0, 20.0, 35.0, 40.0).forEach { invoke(it, 100.0) }

    assertEquals(listOf(10.0, 20.0, 35.0), calls)
  }
}
