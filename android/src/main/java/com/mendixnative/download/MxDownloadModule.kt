package com.mendixnative.download

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.download.NativeDownloadModule
import com.mendixnative.NativeMxDownloadSpec

@ReactModule(name = MxDownloadModule.NAME)
class MxDownloadModule(reactContext: ReactApplicationContext) :
    NativeMxDownloadSpec(reactContext) {

  private val downloadModule = NativeDownloadModule(reactContext)

  override fun getName(): String = NAME

  override fun download(url: String, downloadPath: String, config: ReadableMap, promise: Promise) {
    downloadModule.download(url, downloadPath, config, promise)
  }

  companion object {
    const val NAME = "MxDownload"
  }
}
