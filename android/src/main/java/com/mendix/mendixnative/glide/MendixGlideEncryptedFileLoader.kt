package com.mendix.mendixnative.glide

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import com.bumptech.glide.Priority
import com.bumptech.glide.load.DataSource
import com.bumptech.glide.load.Options
import com.bumptech.glide.load.data.DataFetcher
import com.bumptech.glide.load.model.ModelLoader
import com.bumptech.glide.load.model.ModelLoaderFactory
import com.bumptech.glide.load.model.MultiModelLoaderFactory
import com.bumptech.glide.signature.ObjectKey
import com.mendix.mendixnative.react.fs.FileBackend
import java.io.IOException
import java.io.InputStream
import java.security.GeneralSecurityException
import java.util.*

class MendixGlideEncryptedFileLoader<Data>(private val factory: LocalUriFetcherFactory<Data>) :
  ModelLoader<Uri, Data> {
  override fun buildLoadData(
    uri: Uri, width: Int, height: Int, options: Options
  ): ModelLoader.LoadData<Data> {
    return ModelLoader.LoadData(ObjectKey(uri), factory.build(uri))
  }

  override fun handles(uri: Uri): Boolean {
    return SCHEMES.contains(uri.scheme)
  }

  interface LocalUriFetcherFactory<Data> {
    fun build(uri: Uri): DataFetcher<Data>
  }

  class StreamFactory(private val context: Context) : ModelLoaderFactory<Uri, InputStream>,
    LocalUriFetcherFactory<InputStream> {
    override fun build(multiFactory: MultiModelLoaderFactory): ModelLoader<Uri, InputStream> {
      return MendixGlideEncryptedFileLoader(this)
    }

    override fun teardown() {
      // Nothing
    }

    override fun build(uri: Uri): DataFetcher<InputStream> {
      return EncryptedLocalUriFetcher(context, uri)
    }
  }

  companion object {
    private val SCHEMES = Collections.unmodifiableSet(
      HashSet(listOf(ContentResolver.SCHEME_FILE))
    )
  }
}

class EncryptedLocalUriFetcher(context: Context, private val uri: Uri) :
  DataFetcher<InputStream> {
  private val fileBackend: FileBackend = FileBackend(context)

  override fun loadData(
    priority: Priority, callback: DataFetcher.DataCallback<in InputStream?>
  ) {
    try {
      callback.onDataReady(
        fileBackend.getFileInputStream(uri.toString().replace(uri.scheme + "://", "/"))
      )
    } catch (e: GeneralSecurityException) {
      callback.onLoadFailed(e)
    } catch (e: IOException) {
      callback.onLoadFailed(e)
    }
  }

  override fun cleanup() {
    // nothing I guess.
  }

  override fun cancel() {
    // nothing I guess.
  }

  override fun getDataClass(): Class<InputStream> {
    return InputStream::class.java
  }

  override fun getDataSource(): DataSource {
    return DataSource.LOCAL
  }

}
