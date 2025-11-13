package com.mendix.mendixnative.api

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.databind.ObjectMapper
import com.mendix.mendixnative.config.AppUrl
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import java.io.IOException
import java.util.concurrent.TimeUnit

val client: OkHttpClient =
  OkHttpClient.Builder().connectTimeout(3, TimeUnit.SECONDS).callTimeout(10, TimeUnit.SECONDS)
    .build()

enum class ResponseStatus {
  INACCESSIBLE,
  SUCCEEDED,
  FAILED
}

fun getRuntimeInfo(runtimeUrl: String, cb: (info: RuntimeInfoResponse) -> Unit) {
  client.newCall(
    Request.Builder()
      .post(
        RequestBody.create(
          "application/json; charset=utf-8".toMediaTypeOrNull(),
          "{\"action\":\"info\"}"
        )
      )
      .url(AppUrl.removeTrailingSlash(AppUrl.ensureProtocol(runtimeUrl)) + "/xas/")
      .build()
  )
    .enqueue(object : Callback {
      override fun onFailure(call: Call, e: IOException) {
        cb(RuntimeInfoResponse(null, ResponseStatus.INACCESSIBLE))
      }

      override fun onResponse(call: Call, response: Response) {
        val body = response.body?.string()
        if (!response.isSuccessful || body == null) {
          cb(RuntimeInfoResponse(null, ResponseStatus.FAILED))
          return
        }
        try {
          cb(
            RuntimeInfoResponse(
              ObjectMapper().readValue(body, RuntimeInfo::class.java),
              ResponseStatus.SUCCEEDED
            )
          )
        } catch (e: Exception) {
          cb(RuntimeInfoResponse(null, ResponseStatus.FAILED))
        }
      }
    })
}

class RuntimeInfoResponse(val data: RuntimeInfo?, val responseStatus: ResponseStatus)

@JsonIgnoreProperties(ignoreUnknown = true)
class RuntimeInfo {
  var cachebust: String = ""
  var version: String = ""
  var packagerPort: Int? = null
  var nativeBinaryVersion: Int? = -1
}
