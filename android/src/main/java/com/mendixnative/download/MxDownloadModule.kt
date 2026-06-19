package com.mendixnative.download

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.download.NativeDownloadModule
import com.mendixnative.NativeMxDownloadSpec

@ReactModule(name = MxDownloadModule.NAME)
class MxDownloadModule(reactContext: ReactApplicationContext) :
    NativeMxDownloadSpec(reactContext) {

  // Pass event emitter callback to NativeDownloadModule
  private val downloadModule = NativeDownloadModule(
    reactContext,
    eventEmitter = { receivedBytes, totalBytes ->
      emitOnDownloadProgress(receivedBytes, totalBytes)
    }
  )

  override fun getName(): String = NAME

  override fun download(url: String, downloadPath: String, config: ReadableMap, promise: Promise) {
    downloadModule.download(url, downloadPath, config, promise)
  }

  /**
  * Emit download progress event.
  * This matches the codegen pattern: readonly onDownloadProgress: EventEmitter<DownloadProgress>
  * Codegen generates the base addListener/removeListeners methods automatically.
  */
  private fun emitOnDownloadProgress(receivedBytes: Double, totalBytes: Double) {
    val params = Arguments.createMap().apply {
      putDouble("receivedBytes", receivedBytes)
      putDouble("totalBytes", totalBytes)
    }
    // Emit via the codegen-generated event emitter
    // Event name matches the spec: onDownloadProgress
    emitOnDownloadProgress(params)
  }

  companion object {
    const val NAME = "MxDownload"
  }
}
