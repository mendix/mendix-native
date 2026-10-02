package com.mendix.mendixnative.react.download

import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import java.io.*
import java.net.ConnectException

@Throws(
  IllegalArgumentException::class,
  ConnectException::class,
  FileAlreadyExistsException::class,
  NoDataException::class,
  FileCorruptionException::class,
  IOException::class,
  SecurityException::class,
  ConnectException::class,
  DownloadMimeTypeException::class
)

fun downloadFile(
  client: OkHttpClient,
  url: String,
  downloadPath: String,
  onSuccess: () -> Unit,
  onFailure: (e: Exception) -> Unit,
  progressCallback: (receivedBytes: Double, totalBytes: Double) -> Unit = { _, _ -> },
) {
  downloadFile(client, url, downloadPath, null, onSuccess, onFailure, progressCallback)
}

fun downloadFile(
  client: OkHttpClient,
  url: String,
  downloadPath: String,
  expectedMimeType: String?,
  onSuccess: () -> Unit,
  onFailure: (e: Exception) -> Unit,
  progressCallback: (receivedBytes: Double, totalBytes: Double) -> Unit = { _, _ -> },
) {
  val outputFile = File(downloadPath)
  if (outputFile.exists()) throw FileAlreadyExistsException(outputFile)
  outputFile.parentFile?.mkdirs()
  outputFile.createNewFile()

  try {
    client.newCall(Request.Builder().url(url).get().build()).enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) {
        outputFile.delete()
        onFailure(e)
      }

      override fun onResponse(call: Call, response: Response) {
        try {
          DownloadResponseHandler(
            response,
            expectedMimeType,
            outputFile,
            progressCallback,
          ).handle()
          onSuccess()
        } catch (e: Exception) {
          onFailure(e)
        }
      }
    })
  } catch (e: Exception) {
    outputFile.delete()
    throw e
  }
}


private const val COPY_BUFFER_SIZE = 64 * 1024
private const val UNKNOWN_LENGTH_PROGRESS_INTERVAL = 64.0 * 1024

fun makeProgressCallbackInvoker(
  bytesInterval: Double,
  cb: (receivedBytes: Double, totalBytes: Double) -> Unit
): (Double, Double) -> Unit {
  var invokeNext = bytesInterval
  return fun(receivedBytes: Double, totalBytes: Double) {
    if (receivedBytes >= invokeNext) {
      invokeNext = receivedBytes + bytesInterval
      cb.invoke(receivedBytes, totalBytes)
    }
  }
}

class DownloadResponseHandler(
  private val response: Response,
  private val expectedMimeType: String?,
  private val outputFile: File,
  private val progressCallback: (receivedBytes: Double, totalBytes: Double) -> Unit = { _, _ -> },
) {
  @Throws(ConnectException::class, NoDataException::class, DownloadMimeTypeException::class)
  fun handle() {
    var inputStream: BufferedInputStream? = null
    var outputStream: BufferedOutputStream? = null
    try {
      if (!response.isSuccessful) throw HttpStatusException(response.code)
      if (response.body == null) throw NoDataException()
      val body = response.body
      if (expectedMimeType != null && !mimeTypeMatches(body?.contentType(), expectedMimeType)) {
        throw DownloadMimeTypeException()
      }


      inputStream = BufferedInputStream(body!!.byteStream())

      outputStream =
        BufferedOutputStream(FileOutputStream(outputFile))

      val totalBytes = response.body!!.contentLength().toDouble()
      var reportedBytes = -1.0
      val progressCallbackInvoker = makeProgressCallbackInvoker(
        // Without a content length (-1), report progress every 64 KB instead of every 1%.
        if (totalBytes > 0) totalBytes / 100 else UNKNOWN_LENGTH_PROGRESS_INTERVAL,
      ) { received, total ->
        reportedBytes = received
        progressCallback(received, total)
      }

      var receivedBytes = 0.0
      val buffer = ByteArray(COPY_BUFFER_SIZE)
      var read = inputStream.read(buffer)
      while (read != -1) {
        outputStream.write(buffer, 0, read)
        receivedBytes += read
        progressCallbackInvoker(receivedBytes, totalBytes)
        read = inputStream.read(buffer)
      }
      // Always report completion, even when the last chunk didn't reach the next interval.
      if (reportedBytes != receivedBytes) {
        progressCallback(receivedBytes, totalBytes)
      }
      outputStream.flush()
    } catch (e: Exception) {
      outputFile.delete()
      throw e
    } finally {
      outputStream?.close()
      inputStream?.close()
    }
  }
}

/**
 * Compares type and subtype only, so parameters such as `charset` are ignored.
 * A response without a content type doesn't match.
 */
internal fun mimeTypeMatches(actual: MediaType?, expected: String): Boolean {
  val expectedType = expected.toMediaTypeOrNull() ?: return false
  return actual != null &&
    actual.type.equals(expectedType.type, ignoreCase = true) &&
    actual.subtype.equals(expectedType.subtype, ignoreCase = true)
}

/** Thrown for a non-2xx response. Extends ConnectException, which was thrown before, for compatibility. */
class HttpStatusException(val statusCode: Int) : ConnectException("Download failed with HTTP status $statusCode")
class NoDataException : IllegalStateException()
class FileCorruptionException : IllegalStateException()
class DownloadMimeTypeException : RuntimeException()
