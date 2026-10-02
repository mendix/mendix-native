package com.mendix.mendixnative.react.download

import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okio.Buffer
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
import kotlin.random.Random
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

  private fun download(
    file: File,
    mimeType: String? = null,
    progress: (receivedBytes: Double, totalBytes: Double) -> Unit = { _, _ -> },
  ): Result {
    val result = Result()
    downloadFile(
      client = client,
      url = server.url("/file").toString(),
      downloadPath = file.absolutePath,
      expectedMimeType = mimeType,
      onSuccess = { result.succeeded = true; result.latch.countDown() },
      onFailure = { result.error = it; result.latch.countDown() },
      progressCallback = progress,
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

    // Still a ConnectException, as before, for callers that check for it.
    assertTrue(result.error is ConnectException)
    assertEquals(404, (result.error as HttpStatusException).statusCode)
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
  fun mimeTypeWithParametersMatches() {
    server.enqueue(MockResponse().setHeader("Content-Type", "Text/Plain; charset=utf-8").setBody("content"))
    val file = File(tempFolder.root, "file.txt")

    val result = download(file, mimeType = "text/plain")

    assertNull(result.error)
    assertEquals("content", file.readText())
  }

  @Test
  fun expectedMimeTypeWithParametersMatches() {
    server.enqueue(MockResponse().setHeader("Content-Type", "text/plain").setBody("content"))

    val result = download(File(tempFolder.root, "file.txt"), mimeType = "text/plain; charset=utf-8")

    assertNull(result.error)
  }

  @Test
  fun missingContentTypeFailsWhenMimeTypeIsSet() {
    server.enqueue(MockResponse().setBody("content"))
    val file = File(tempFolder.root, "file.txt")

    val result = download(file, mimeType = "text/plain")

    assertTrue(result.error is DownloadMimeTypeException)
    assertFalse(file.exists())
  }

  @Test
  fun invalidExpectedMimeTypeFails() {
    server.enqueue(MockResponse().setBody("content"))

    val result = download(File(tempFolder.root, "file.txt"), mimeType = "not a mime type")

    assertTrue(result.error is DownloadMimeTypeException)
  }

  @Test
  fun missingContentTypeSucceedsWithoutMimeType() {
    server.enqueue(MockResponse().setBody("content"))

    assertNull(download(File(tempFolder.root, "file.txt")).error)
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

  private fun randomBytes(size: Int) = Random(42).nextBytes(size)

  private fun assertMonotonic(events: List<Pair<Double, Double>>) {
    events.zipWithNext().forEach { (a, b) -> assertTrue("$a then $b", b.first > a.first) }
  }

  @Test
  fun largeBodyIsWrittenIntactWithBoundedProgress() {
    val bytes = randomBytes(1024 * 1024)
    // Throttling splits the body over many reads, like a real network.
    server.enqueue(MockResponse().setBody(Buffer().write(bytes)).throttleBody(64 * 1024, 5, TimeUnit.MILLISECONDS))
    val file = File(tempFolder.root, "large.bin")
    val events = mutableListOf<Pair<Double, Double>>()

    val result = download(file) { received, total -> events.add(received to total) }

    assertNull(result.error)
    assertTrue(bytes.contentEquals(file.readBytes()))
    assertTrue("${events.size} events", events.size in 2..101)
    assertMonotonic(events)
    assertTrue(events.all { it.second == bytes.size.toDouble() && it.first <= it.second })
    assertEquals(bytes.size.toDouble(), events.last().first, 0.0)
  }

  @Test
  fun bodyWithoutContentLengthReportsProgressPerInterval() {
    val bytes = randomBytes(300 * 1024 + 7)
    server.enqueue(MockResponse().setChunkedBody(Buffer().write(bytes), 1024))
    val file = File(tempFolder.root, "chunked.bin")
    val events = mutableListOf<Pair<Double, Double>>()

    val result = download(file) { received, total -> events.add(received to total) }

    assertNull(result.error)
    assertTrue(bytes.contentEquals(file.readBytes()))
    // One event per 64 KB plus the final one.
    assertTrue("${events.size} events", events.size in 2..6)
    assertMonotonic(events)
    assertTrue(events.all { it.second == -1.0 })
    assertEquals(bytes.size.toDouble(), events.last().first, 0.0)
  }

  @Test
  fun smallBodyReportsCompletion() {
    server.enqueue(MockResponse().setBody("content"))
    val events = mutableListOf<Pair<Double, Double>>()

    download(File(tempFolder.root, "small.txt")) { received, total -> events.add(received to total) }

    assertEquals(listOf(7.0 to 7.0), events)
  }
}
