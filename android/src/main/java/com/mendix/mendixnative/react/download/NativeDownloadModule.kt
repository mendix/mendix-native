package com.mendix.mendixnative.react.download

import com.facebook.react.bridge.*
import okhttp3.OkHttpClient
import java.io.IOException
import java.net.ConnectException
import java.util.concurrent.TimeUnit

class NativeDownloadModule(
  val context: ReactApplicationContext,
  private val eventEmitter: ((Double, Double) -> Unit)? = null
) {
  val client = OkHttpClient()

  fun download(
    url: String,
    downloadPath: String,
    config: ReadableMap,
    promise: Promise
  ) {

    val timeout =
      if (config.hasKey(TIMEOUT_KEY)) config.getInt(TIMEOUT_KEY) else TIMEOUT
    val mimeType = if (config.hasKey(MIME_TYPE_KEY)) config.getString(MIME_TYPE_KEY) else null

    val reject = { e: Exception ->
      val (code, message) = downloadErrorFor(e)
      promise.reject(code, message, e)
    }
    try {
      downloadFile(
        client.newBuilder()
          .connectTimeout(timeout.toLong(), TimeUnit.MILLISECONDS).build(),
        url,
        downloadPath,
        mimeType,
        { promise.resolve(null) },
        reject
      ) { receivedBytes, totalBytes ->
        eventEmitter?.invoke(receivedBytes, totalBytes)
      }
    } catch (e: Exception) {
      // Thrown before the request starts, e.g. for an existing destination or an invalid URL.
      reject(e)
    }
  }

  companion object {
    const val TIMEOUT_KEY = "connectionTimeout"
    const val MIME_TYPE_KEY = "mimeType"
    const val TIMEOUT = 10000

    const val ERROR_DOWNLOAD_FAILED = "ERROR_DOWNLOAD_FAILED"
    const val FILE_ALREADY_EXISTS = "FILE_ALREADY_EXISTS"
    const val ERROR_CONNECTION_FAILED = "ERROR_CONNECTION_FAILED"
    const val FS_ACCESS_EXCEPTION = "FS_ACCESS_EXCEPTION"
    const val IO_EXCEPTION = "IO_EXCEPTION"
  }
}

/**
 * Maps a download failure to a rejection code and message, using the same codes as iOS.
 * Subclasses come before their parents: FileAlreadyExistsException, DownloadFileException and ConnectException
 * are all IOExceptions. Any other IOException comes from the network.
 */
internal fun downloadErrorFor(e: Exception): Pair<String, String> = when (e) {
  is DownloadMimeTypeException -> NativeDownloadModule.ERROR_DOWNLOAD_FAILED to "Mime type check failed"
  is FileAlreadyExistsException -> NativeDownloadModule.FILE_ALREADY_EXISTS to "File already exists"
  is NoDataException -> NativeDownloadModule.ERROR_CONNECTION_FAILED to "No data found"
  is FileCorruptionException -> NativeDownloadModule.IO_EXCEPTION to "File corrupted"
  is HttpStatusException -> NativeDownloadModule.ERROR_DOWNLOAD_FAILED to "Download failed with HTTP status ${e.statusCode}"
  is DownloadFileException -> NativeDownloadModule.IO_EXCEPTION to "Could not write file"
  is ConnectException -> NativeDownloadModule.ERROR_DOWNLOAD_FAILED to "Failed to connect to endpoint"
  is IOException -> NativeDownloadModule.ERROR_DOWNLOAD_FAILED to "Download failed"
  is SecurityException -> NativeDownloadModule.FS_ACCESS_EXCEPTION to "Access to filesystem denied"
  else -> NativeDownloadModule.ERROR_DOWNLOAD_FAILED to "Failed to download file"
}
