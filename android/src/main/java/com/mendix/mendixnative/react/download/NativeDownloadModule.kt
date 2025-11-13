package com.mendix.mendixnative.react.download

import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import okhttp3.OkHttpClient
import java.io.IOException
import java.net.ConnectException
import java.util.concurrent.TimeUnit

class NativeDownloadModule(val context: ReactApplicationContext) {
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

    downloadFile(
      client.newBuilder()
        .connectTimeout(timeout.toLong(), TimeUnit.MILLISECONDS).build(),
      url,
      downloadPath,
      mimeType,
      { promise.resolve(null) },
      { e ->
        when (e) {
          is DownloadMimeTypeException -> promise.reject(
            ERROR_DOWNLOAD_FAILED,
            "Mime type check failed",
            e
          )

          is FileAlreadyExistsException -> promise.reject(
            FILE_ALREADY_EXISTS,
            "File already exists",
            e
          )

          is NoDataException -> promise.reject(
            ERROR_CONNECTION_FAILED,
            "No data found",
            e
          )

          is FileCorruptionException -> promise.reject(IO_EXCEPTION, "File corrupted", e)
          is IOException -> promise.reject(IO_EXCEPTION, "IO exception", e)
          is SecurityException -> promise.reject(
            FS_ACCESS_EXCEPTION,
            "Access to filesystem denied",
            e
          )

          is ConnectException -> promise.reject(
            ERROR_DOWNLOAD_FAILED,
            "Failed to connect to endpoint",
            e
          )

          else -> promise.reject(ERROR_DOWNLOAD_FAILED, "Failed to download file", e)
        }
      }
    ) { receivedBytes, totalBytes ->
      postProgressEvent(
        receivedBytes,
        totalBytes
      )
    }
  }

  private fun postProgressEvent(receivedBytes: Double, totalBytes: Double) {
    val params = Arguments.createMap()
    params.putDouble("receivedBytes", receivedBytes)
    params.putDouble("totalBytes", totalBytes)
    context
      .getJSModule(RCTDeviceEventEmitter::class.java)
      .emit(DOWNLOAD_PROGRESS_EVENT, params)
  }

  companion object {
    val supportedEvents: Array<String> = arrayOf(DOWNLOAD_PROGRESS_EVENT)

    const val TIMEOUT_KEY = "connectionTimeout"
    const val MIME_TYPE_KEY = "mimeType"
    const val TIMEOUT = 10000

    const val DOWNLOAD_PROGRESS_EVENT = "NDM_DOWNLOAD_PROGRESS_EVENT"
    const val ERROR_DOWNLOAD_FAILED = "ERROR_DOWNLOAD_FAILED"
    const val FILE_ALREADY_EXISTS = "FILE_ALREADY_EXISTS"
    const val ERROR_CONNECTION_FAILED = "ERROR_CONNECTION_FAILED"
    const val FS_ACCESS_EXCEPTION = "FS_ACCESS_EXCEPTION"
    const val IO_EXCEPTION = "IO_EXCEPTION"
  }
}


