package com.mendix.mendixnative.request

import android.util.Log
import com.mendix.mendixnative.config.AppUrl
import com.mendix.mendixnative.encryption.decryptValue
import com.mendix.mendixnative.encryption.encryptValue
import com.mendix.mendixnative.react.MxConfiguration
import okhttp3.*
import okhttp3.HttpUrl.Companion.toHttpUrl

/**
 * OkHttp interceptor handling cookie encryption for all app related cookies that use the React Native
 * OkHttp factory to get a client.
 */
class MendixNetworkInterceptor : Interceptor {
  override fun intercept(chain: Interceptor.Chain): Response {
    val request = chain.request()
    val requestUrl = request.url
    val runtimeUrl = AppUrl.forRuntime(MxConfiguration.runtimeUrl).toHttpUrl()

    return if (runtimeUrl.host != requestUrl.host)
      chain.proceed(request)
    else
      chain.proceed(request.withDecryptedCookies()).withEncryptedCookies()
  }
}

const val ivDelimiter =
  "___enc___" // Delimits encoded value and Initialization Vector used by encryption
const val encryptedCookieKeyPrefix = "MxEnc" // Prefix for encrypted cookie keys

/**
 * Request extension to decrypt possibly encrypted cookies
 */
fun Request.withDecryptedCookies(): Request {
  // Skip empty segments, e.g. from a trailing "; ".
  val cookiePairs = this.header("Cookie")?.split(";")?.map { it.trim() }?.filter { it.isNotEmpty() }
    ?: return this
  val encryptedCookieExists =
    cookiePairs.any { cookie -> cookie.startsWith(encryptedCookieKeyPrefix) }
  val decryptedCookies = cookiePairs.mapNotNull {
    if (!encryptedCookieExists) {
      return@mapNotNull it
    }

    // A cookie without "=" has no value, so it can't be an encrypted one.
    val parts = it.split("=", limit = 2)
    val key = parts[0]
    val value = parts.getOrNull(1)
    if (!key.startsWith(encryptedCookieKeyPrefix)) {
      return@mapNotNull null
    }

    try {
      val params = cookieValueToDecryptionParams(
        value ?: throw IllegalArgumentException("Cookie has no value")
      )
      val decryptedValue = decryptValue(params.first, params.second)
      return@mapNotNull "${key.removePrefix(encryptedCookieKeyPrefix)}=$decryptedValue"
    } catch (e: Exception) {
      Log.w("MendixNetworkInterceptor", "Failed to decrypt cookie $key, dropping it", e)
      return@mapNotNull null
    }
  }.joinToString(separator = "; ")

  val builder = this.newBuilder().removeHeader("Cookie")
  // When no cookie is left (e.g. none could be decrypted), send none rather than the encrypted ones.
  if (decryptedCookies.isNotBlank()) {
    builder.addHeader("Cookie", decryptedCookies)
  }
  return builder.build()
}

/**
 * Response extension to encrypt cookies
 * It maps the cookies to pairs that represent the encrypted cookie to be set and a version of its unencrypted
 * equivalent to be removed.
 * Finally it iterates over the pairs and creates Set-Cookie headers both for setting the encrypted cookie
 * and removing the unencrypted cookie.
 */
fun Response.withEncryptedCookies(): Response {
  val cookies = Cookie.parseAll(this.request.url, this.headers)
  val encryptedCookiesPairs = cookies.map {
    val newCookie = makeCookie(
      name = getEncryptedCookieName(it.name),
      value = encryptionResultToCookieValue(encryptValue(it.value)),
      hostOnlyDomain = it.domain,
      path = it.path,
      httpOnly = it.httpOnly,
      secure = it.secure,
      expiresAt = it.expiresAt
    )
    val unencryptedExpiredCookie =
      makeCookie(it.name, "", it.domain, it.path, it.httpOnly, it.secure, -1)
    return@map Pair(newCookie, unencryptedExpiredCookie)
  }
  val headerBuilder = this.headers.newBuilder()
  headerBuilder.removeAll("Set-Cookie")
  encryptedCookiesPairs.forEach {
    headerBuilder.add("Set-Cookie", it.first.toString())
    headerBuilder.add("Set-Cookie", it.second.toString())
  }
  return this.newBuilder().headers(headerBuilder.build()).build()
}

fun makeCookie(
  name: String,
  value: String,
  hostOnlyDomain: String,
  path: String,
  httpOnly: Boolean,
  secure: Boolean,
  expiresAt: Long,
): Cookie {
  return Cookie.Builder().let {
    it.name(name).value(value).hostOnlyDomain(hostOnlyDomain).path(path).expiresAt(expiresAt)
    if (httpOnly) it.httpOnly()
    if (secure) it.secure()
    it.build()
  }
}

fun getEncryptedCookieName(name: String) = "$encryptedCookieKeyPrefix${name}"

fun cookieValueToDecryptionParams(value: String): Pair<String, String?> {
  val parts = value.split(ivDelimiter)
  return Pair(parts[0], if (parts.size > 1) parts[1] else null)
}


fun encryptionResultToCookieValue(triple: Triple<ByteArray, ByteArray?, Boolean>): String {
  return "\"${triple.first.decodeToString()}${if (triple.third) "${ivDelimiter}${triple.second!!.decodeToString()}" else ""}\"".replace(
    "\n".toRegex(),
    ""
  )
}
