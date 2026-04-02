package com.mendixnative.fs

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.fs.NativeFsModule
import com.mendixnative.NativeMxFileSystemSpec

@ReactModule(name = MxFileSystemModule.NAME)
class MxFileSystemModule(reactContext: ReactApplicationContext) :
    NativeMxFileSystemSpec(reactContext) {

  private val fsModule = NativeFsModule(reactContext)

  override fun getName(): String = NAME

  override fun constants(): WritableMap? {
    return fsModule.getConstants()
  }

  override fun save(blob: ReadableMap, filePath: String, promise: Promise) {
    fsModule.save(blob, filePath, promise)
  }

  override fun read(filePath: String, promise: Promise) {
    fsModule.read(filePath, promise)
  }

  override fun move(filePath: String, newPath: String, promise: Promise) {
    fsModule.move(filePath, newPath, promise)
  }

  override fun remove(filePath: String, promise: Promise) {
    fsModule.remove(filePath, promise)
  }

  override fun list(dirPath: String, promise: Promise) {
    fsModule.list(dirPath, promise)
  }

  override fun readAsDataURL(filePath: String, promise: Promise) {
    fsModule.readAsDataURL(filePath, promise)
  }

  override fun readAsText(filePath: String, promise: Promise) {
    fsModule.readAsText(filePath, promise)
  }

  override fun fileExists(filePath: String, promise: Promise) {
    fsModule.fileExists(filePath, promise)
  }

  override fun writeJson(data: ReadableMap, filepath: String, promise: Promise) {
    fsModule.writeJson(data, filepath, promise)
  }

  override fun readJson(filepath: String, promise: Promise) {
    fsModule.readJson(filepath, promise)
  }

  override fun setEncryptionEnabled(enabled: Boolean) {
    fsModule.setEncryptionEnabled(enabled)
  }

  companion object {
    const val NAME = "MxFileSystem"
  }
}
