package com.mendix.mendixnative.react.fs

import android.content.Context
import android.os.Build
import androidx.security.crypto.EncryptedFile
import com.fasterxml.jackson.databind.JsonMappingException
import com.fasterxml.jackson.databind.ObjectMapper
import com.mendix.mendixnative.encryption.getMasterKey
import java.io.*
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.GeneralSecurityException
import java.util.*
import java.util.zip.ZipEntry
import java.util.zip.ZipFile

val FILE_ENCRYPTION_SCHEME = EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB

class FileBackend(val context: Context) {
  private var encryptionEnabled = false

  fun setEncryptionEnabled(encryptionEnabled: Boolean) {
    this.encryptionEnabled = encryptionEnabled
  }

  @Throws(IOException::class)
  fun save(data: ByteArray, filePath: String) {

    if (this.encryptionEnabled && !isOfflineFile(filePath)) {
      val isOverride = exists(filePath)
      val outputFilePath = if (isOverride) getTempFilePath(filePath) else filePath

      getEncryptedFileOutputStream(outputFilePath).apply {
        write(data)
        flush()
        close()
      }

      if (isOverride) {
        moveFile(outputFilePath, filePath)
      }
    } else {
      getUnencryptedFileOutputStream(data, filePath)
    }
  }

  @Throws(IOException::class)
  fun read(filePath: String): ByteArray {
    return try {
      if (this.encryptionEnabled) {
        readAsEncryptedFile(filePath)
      } else {
        readAsUnencryptedFile(filePath)
      }
    } catch (_: IOException) {
      readAsUnencryptedFile(filePath)
    }
  }

  @Throws(IOException::class, GeneralSecurityException::class)
  private fun getEncryptedFileOutputStream(filePath: String): FileOutputStream {
    val file = File(filePath)
    val encryptedFile = EncryptedFile.Builder(
      this.context,
      file,
      getMasterKey(this.context),
      FILE_ENCRYPTION_SCHEME
    ).build()

    if (file.exists()) {
      file.delete()
    }

    file.parentFile?.mkdirs()

    return encryptedFile.openFileOutput()
  }

  private fun getUnencryptedFileOutputStream(data: ByteArray, filePath: String) {
    File(filePath).parentFile?.mkdirs()
    FileOutputStream(filePath).use { outputStream -> outputStream.write(data) }
  }


  @Throws(IOException::class, GeneralSecurityException::class)
  fun getFileInputStream(filePath: String): InputStream {
    val file = File(filePath)
    val encryptedFile = EncryptedFile.Builder(
      context,
      file,
      getMasterKey(context),
      FILE_ENCRYPTION_SCHEME
    ).build()
    return encryptedFile.openFileInput()
  }

  @Throws(IOException::class)
  fun moveFile(filePath: String, newPath: String) {
    val src = File(filePath)
    val dest = File(newPath)
    if (encryptionEnabled || !moveFileByRename(src, dest)) {
      val data = read(filePath)
      dest.parentFile?.mkdirs()
      FileOutputStream(newPath).use { outputStream ->
        outputStream.write(data)
        File(filePath).delete()
      }
    }
  }

  fun deleteFile(filePath: String) {
    delete(File(filePath))
  }

  fun deleteDirectory(directoryPath: String) {
    deleteDirectory(File(directoryPath))
  }

  fun list(dirPath: String): Array<String> {
    val directory = File(dirPath)
    return directory.list() ?: emptyArray()
  }

  fun exists(filePath: String): Boolean {
    return File(filePath).exists()
  }

  fun isDirectory(filePath: String): Boolean {
    return File(filePath).isDirectory
  }

  fun copyAssetToPath(context: Context, assetName: String, toFilePath: String) {
    context.assets.open(assetName).let { inputStream ->
      val outFile = File(toFilePath)
      outFile.parentFile.let { parent ->
        parent?.mkdirs()
      }
      val out = FileOutputStream(outFile)
      val buffer = ByteArray(1024)
      var read: Int
      while (inputStream.read(buffer).also { read = it } != -1) {
        out.write(buffer, 0, read)
      }
      inputStream.close()
      out.flush()
      out.close()
    }
  }

  fun unzip(zipPath: File, directory: File) {
    unzip(zipPath.absolutePath, directory.absolutePath)
  }

  fun unzip(zipPath: String, directory: String) {
    ZipFile(zipPath).use { zip ->
      zip.entries().asSequence().map { zipEntry ->
        val file = File(directory, zipEntry.name)
        file.parentFile?.run { mkdirs() }
        listOf(zipEntry, file)
      }.filter {
        !(it[0] as ZipEntry).isDirectory
      }.forEach {
        zip.getInputStream(it[0] as ZipEntry).use { input ->
          (it[1] as File).outputStream().use { output ->
            input.copyTo(output)
          }
        }
      }
    }
  }

  @Throws(JsonMappingException::class, IOException::class)
  fun writeJson(map: HashMap<String, Any>, filepath: String) {
    val bytes =
      ObjectMapper().writerWithDefaultPrettyPrinter().writeValueAsBytes(map)
    save(bytes, filepath)
  }

  fun writeUnencryptedJson(map: HashMap<String, Any>, filepath: String) {
    val bytes =
      ObjectMapper().writerWithDefaultPrettyPrinter().writeValueAsBytes(map)
    getUnencryptedFileOutputStream(bytes, filepath)
  }


  fun moveDirectory(
    src: String,
    dst: String,
  ): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val dstFile = File(dst)
      dstFile.parentFile?.mkdirs()
      try {
        Files.move(
          File(src).toPath(),
          dstFile.toPath(),
          StandardCopyOption.REPLACE_EXISTING
        )
        true
      } catch (e: Exception) {
        e.printStackTrace()
        false
      }
    } else {
      val directory = File(src)
      require(directory.isDirectory) { return false }
      val files = collectFilesInDirectory(directory).reversed()
      files.forEach {
        if (!it.isDirectory) {
          val filePath = it.absolutePath
          val toFilePath = filePath.replace(src, dst)
          moveFile(filePath, toFilePath)
        }
      }
      deleteDirectory(src)
      true
    }
  }

  fun deleteDirectory(directory: File) {
    if (!directory.isDirectory) return
    val files = collectFilesInDirectory(directory).toList().reversed()
    files.forEach { it.delete() }
  }

  private fun collectFilesInDirectory(directory: File): Array<File> =
    require(directory.isDirectory).let {
      arrayOf(directory).apply {
        for (file in directory.listFiles() ?: emptyArray<File>()) {
          if (file.isDirectory) this.plus(collectFilesInDirectory(file))
          else this.plus(file)
        }
      }
    }

  private fun moveFileByRename(src: File, dest: File): Boolean {
    return try {
      require(src.exists() && src.isFile)
      dest.parentFile?.mkdirs()
      src.renameTo(dest)
    } catch (e: java.lang.Exception) {
      e.printStackTrace()
      false
    }
  }

  private fun delete(file: File) {
    file.delete()
  }

  @Throws(IOException::class)
  private fun readAsEncryptedFile(filePath: String): ByteArray {
    val inputStream = getFileInputStream(filePath)
    return inputStream.readBytes()
  }

  @Throws(IOException::class)
  fun readAsUnencryptedFile(filePath: String): ByteArray {
    val inputStream = File(filePath).inputStream()
    return inputStream.readBytes()
  }

  private fun getTempFilePath(filePath: String): String {
    return filePath + "temp"
  }

  private fun isOfflineFile(filePath: String): Boolean {
    return filePath.contains("GUID")
  }

}
