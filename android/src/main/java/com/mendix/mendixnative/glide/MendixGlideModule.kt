package com.mendix.mendixnative.glide

import android.content.Context
import android.net.Uri
import com.bumptech.glide.Glide
import com.bumptech.glide.Registry
import com.bumptech.glide.annotation.GlideModule
import com.bumptech.glide.module.AppGlideModule
import java.io.InputStream

@GlideModule
class MendixGlideModule : AppGlideModule() {
  override fun registerComponents(context: Context, glide: Glide, registry: Registry) {
    registry.prepend(
      Uri::class.java,
      InputStream::class.java,
      MendixGlideEncryptedFileLoader.StreamFactory(context)
    )
  }
}
