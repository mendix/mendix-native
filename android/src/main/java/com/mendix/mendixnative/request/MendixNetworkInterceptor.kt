package com.mendix.mendixnative.request

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
  val cookiePairs = this.header("Cookie")?.split("; ")
  val encryptedCookieExists =
    cookiePairs?.any { cookie -> cookie.startsWith(encryptedCookieKeyPrefix) }
  val decryptedCookies = cookiePairs?.map {
    val (key, value) = it.split("=", limit = 2)

    if (encryptedCookieExists!! && key.startsWith(encryptedCookieKeyPrefix)) {
      val params = cookieValueToDecryptionParams(value)
      val decryptedValue = decryptValue(params.first, params.second)

      return@map "${key.removePrefix(encryptedCookieKeyPrefix)}=$decryptedValue"
    } else if (!encryptedCookieExists) {
      return@map it;
    }

    return@map null
  }?.filterNotNull()?.joinToString(separator = "; ")

  return when {
    decryptedCookies != null && decryptedCookies.isNotBlank() -> this.newBuilder()
      .removeHeader("Cookie")
      .addHeader("Cookie", decryptedCookies).build()

    else -> this
  }
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
