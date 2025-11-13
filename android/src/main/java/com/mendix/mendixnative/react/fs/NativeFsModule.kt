package com.mendix.mendixnative.react.fs

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.modules.blob.BlobModule
import com.facebook.react.modules.blob.FileReaderModule
import com.fasterxml.jackson.core.JsonParseException
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.JsonMappingException
import com.fasterxml.jackson.databind.ObjectMapper
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.nio.charset.StandardCharsets
import java.util.Objects

class NativeFsModule(private val reactContext: ReactApplicationContext) {
  private val fileBackend: FileBackend = FileBackend(reactContext)
  private val filesDir: String = reactContext.filesDir.absolutePath
  private val cacheDir: String = reactContext.cacheDir.absolutePath

  fun setEncryptionEnabled(encryptionEnabled: Boolean) {
    this.fileBackend.setEncryptionEnabled(encryptionEnabled)
  }

  fun save(blob: ReadableMap, filePath: String, promise: Promise) {
    val blobModule = reactContext.getNativeModule<BlobModule?>(BlobModule::class.java)
    val blobId = blob.getString("blobId")

    val bytes = blobModule!!.resolve(blobId, blob.getInt("offset"), blob.getInt("size"))
    if (bytes == null) {
      promise.reject(ERROR_INVALID_BLOB, "The specified blob is invalid")
      return
    }

    try {
      fileBackend.save(bytes, ensureWhiteListedPath(filePath))
    } catch (e: IOException) {
      e.printStackTrace()
      promise.reject(ERROR_CACHE_FAILED, "Failed writing file to disk")
      return
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
      return
    }

    blobModule.release(blobId)
    promise.resolve(null)
  }

  fun read(filePath: String, promise: Promise) {
    try {
      promise.resolve(read(ensureWhiteListedPath(filePath)))
    } catch (_: FileNotFoundException) {
      promise.resolve(null)
    } catch (e: IOException) {
      e.printStackTrace()
      promise.reject(ERROR_READ_FAILED, "Failed reading file from disk")
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
    }
  }

  fun move(filePath: String, newPath: String, promise: Promise) {
    val fromPath: String?
    val toPath: String?

    try {
      fromPath = ensureWhiteListedPath(filePath)
      toPath = ensureWhiteListedPath(newPath)
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
      return
    }

    if (!fileBackend.exists(fromPath)) {
      promise.reject(ERROR_READ_FAILED, "File does not exist")
    }

    try {
      if (fileBackend.isDirectory(fromPath)) {
        fileBackend.moveDirectory(fromPath, toPath)
      } else {
        fileBackend.moveFile(fromPath, toPath)
      }
      promise.resolve(null)
    } catch (e: IOException) {
      e.printStackTrace()
      promise.reject(ERROR_MOVE_FAILED, e)
    }
  }

  fun remove(filePath: String, promise: Promise) {
    try {
      if (fileBackend.isDirectory(filePath)) {
        fileBackend.deleteDirectory(filePath)
      } else {
        fileBackend.deleteFile(ensureWhiteListedPath(filePath))
      }
      promise.resolve(null)
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
    }
  }

  fun list(dirPath: String, promise: Promise) {
    val result = WritableNativeArray()

    /*
     This is for backwards compatibility for a assumption/bug(?) in the client. The client assumes
     it can list any path without verifying its validity and expects to get an empty array back as it chains unconditionally.
    */
    val directory = File(dirPath)
    if (!directory.exists() || !directory.isDirectory()) {
      promise.resolve(result)
      return
    }

    try {
      for (file in Objects.requireNonNull(
        fileBackend.list(
          ensureWhiteListedPath(dirPath)
        )
      )) {
        result.pushString(file)
      }
      promise.resolve(result)
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
    } catch (e: Exception) {
      e.printStackTrace()
      promise.reject(e)
    }
  }

  fun readAsDataURL(filePath: String, promise: Promise) {
    try {
      val fileReaderModule =
        reactContext.getNativeModule(FileReaderModule::class.java)
      fileReaderModule!!.readAsDataURL(read(ensureWhiteListedPath(filePath)), promise)
    } catch (_: FileNotFoundException) {
      promise.resolve(null)
    } catch (e: IOException) {
      e.printStackTrace()
      promise.reject(ERROR_READ_FAILED, "Failed reading file from disk")
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
    }
  }

  fun readAsText(filePath: String, promise: Promise) {
    try {
      promise.resolve(String(fileBackend.read(filePath), StandardCharsets.UTF_8))
    } catch (e: IOException) {
      promise.reject("no text", e)
    }
  }

  fun fileExists(filePath: String, promise: Promise) {
    try {
      promise.resolve(fileBackend.exists(ensureWhiteListedPath(filePath)))
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
    }
  }

  fun writeJson(data: ReadableMap, filepath: String, promise: Promise) {
    try {
      val map = data.toHashMap() as HashMap<String, Any>
      fileBackend.writeJson(map, ensureWhiteListedPath(filepath))
      promise.resolve(null)
    } catch (e: JsonMappingException) {
      e.printStackTrace()
      promise.reject(ERROR_SERIALIZATION_FAILED, "Failed to serialize JSON", e)
    } catch (e: IOException) {
      e.printStackTrace()
      promise.reject(ERROR_CACHE_FAILED, "Failed to write to disk", e)
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
    }
  }

  fun readJson(filepath: String, promise: Promise) {
    try {
      val bytes =
        fileBackend.read(ensureWhiteListedPath(filepath))
      val typeRef: TypeReference<MutableMap<String?, Any?>?> =
        object : TypeReference<MutableMap<String?, Any?>?>() {
        }
      promise.resolve(
        Arguments.makeNativeMap(
          ObjectMapper().readValue<MutableMap<String?, Any?>?>(
            bytes,
            typeRef
          )
        )
      )
    } catch (e: FileNotFoundException) {
      e.printStackTrace()
      promise.resolve("null")
    } catch (e: JsonParseException) {
      e.printStackTrace()
      promise.reject(ERROR_SERIALIZATION_FAILED, "Failed to deserialize JSON", e)
    } catch (e: JsonMappingException) {
      e.printStackTrace()
      promise.reject(ERROR_SERIALIZATION_FAILED, "Failed to deserialize JSON", e)
    } catch (e: IOException) {
      e.printStackTrace()
      promise.reject(ERROR_READ_FAILED, "Failed reading file from disk")
    } catch (e: PathNotAccessibleException) {
      e.printStackTrace()
      promise.reject(INVALID_PATH, e)
    }
  }

  fun getConstants(): WritableMap {
    val constants = WritableNativeMap()
    constants.putString("DocumentDirectoryPath", filesDir)
    constants.putBoolean("SUPPORTS_DIRECTORY_MOVE", true) // Client uses this const to identify if functionality is supported
    constants.putBoolean("SUPPORTS_ENCRYPTION", true)
    return constants
  }

  @Throws(IOException::class)
  private fun read(filePath: String): ReadableMap {
    val data = fileBackend.read(filePath)

    val blobModule = reactContext.getNativeModule(BlobModule::class.java)
    val blob: WritableMap = WritableNativeMap()
    blob.putString("blobId", blobModule!!.store(data))
    blob.putInt("offset", 0)
    blob.putInt("size", data.size)
    return blob
  }

  @Throws(PathNotAccessibleException::class)
  private fun ensureWhiteListedPath(path: String): String {
    if (!(path.startsWith(filesDir) || path.startsWith(cacheDir))) {
      throw PathNotAccessibleException(path)
    }
    return path
  }

  companion object {
    const val NAME: String = "NativeFsModule"

    private const val ERROR_INVALID_BLOB = "ERROR_INVALID_BLOB"
    private const val ERROR_READ_FAILED = "ERROR_READ_FAILED"
    private const val ERROR_CACHE_FAILED = "ERROR_CACHE_FAILED"
    private const val ERROR_MOVE_FAILED = "ERROR_MOVE_FAILED"
    private const val ERROR_SERIALIZATION_FAILED = "ERROR_SERIALIZATION_FAILED"
    private const val INVALID_PATH = "INVALID_PATH"
  }
}
