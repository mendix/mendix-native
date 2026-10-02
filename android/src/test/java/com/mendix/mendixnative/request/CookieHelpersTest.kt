package com.mendix.mendixnative.request

import okhttp3.Request
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

// Robolectric because dropping an undecryptable cookie logs through android.util.Log.
@RunWith(RobolectricTestRunner::class)
class CookieHelpersTest {
  private fun requestWithCookie(cookie: String) =
    Request.Builder().url("https://example.com").header("Cookie", cookie).build()

  @Test
  fun cookieValueToDecryptionParamsSplitsValueAndIv() {
    assertEquals(Pair("value", "iv"), cookieValueToDecryptionParams("value${ivDelimiter}iv"))
    assertEquals(Pair("value", null), cookieValueToDecryptionParams("value"))
  }

  @Test
  fun encryptionResultToCookieValueJoinsWithIvAndStripsNewlines() {
    val value = encryptionResultToCookieValue(Triple("abc\n".toByteArray(), "iv\n".toByteArray(), true))
    assertEquals("\"abc${ivDelimiter}iv\"", value)
  }

  @Test
  fun encryptionResultToCookieValueOmitsIvWhenNotEncrypted() {
    assertEquals("\"abc\"", encryptionResultToCookieValue(Triple("abc".toByteArray(), null, false)))
  }

  @Test
  fun encryptedCookieNameIsPrefixed() {
    assertEquals("${encryptedCookieKeyPrefix}session", getEncryptedCookieName("session"))
  }

  @Test
  fun makeCookieAppliesFlags() {
    val cookie = makeCookie("name", "value", "example.com", "/path", httpOnly = true, secure = true, expiresAt = 1000L)
    assertEquals("name", cookie.name)
    assertEquals("value", cookie.value)
    assertEquals("example.com", cookie.domain)
    assertEquals("/path", cookie.path)
    assertTrue(cookie.httpOnly)
    assertTrue(cookie.secure)
    assertTrue(cookie.hostOnly)
  }

  @Test
  fun requestWithoutCookiesIsUnchanged() {
    val request = Request.Builder().url("https://example.com").build()
    assertSame(request, request.withDecryptedCookies())
  }

  @Test
  fun plainCookiesPassThroughWhenNoneAreEncrypted() {
    val request = requestWithCookie("a=1; b=2=3")
    assertEquals("a=1; b=2=3", request.withDecryptedCookies().header("Cookie"))
  }

  @Test
  fun cookieWithoutValueIsKept() {
    assertEquals("a=1; flag", requestWithCookie("a=1; flag").withDecryptedCookies().header("Cookie"))
  }

  @Test
  fun emptySegmentsAreSkipped() {
    assertEquals("a=1", requestWithCookie("a=1; ").withDecryptedCookies().header("Cookie"))
    assertEquals("a=1; b=2", requestWithCookie("a=1;;b=2").withDecryptedCookies().header("Cookie"))
  }

  @Test
  fun cookieWithEmptyNameIsKept() {
    assertEquals("=1", requestWithCookie("=1").withDecryptedCookies().header("Cookie"))
  }

  @Test
  fun undecryptableCookiesAreNotForwarded() {
    // Without an IV the value can't be decrypted.
    assertNull(requestWithCookie("${encryptedCookieKeyPrefix}session=abc").withDecryptedCookies().header("Cookie"))
  }

  @Test
  fun plainCookiesAreDroppedWhenEncryptedOnesExist() {
    val request = requestWithCookie("a=1; ${encryptedCookieKeyPrefix}session=abc; flag; ${encryptedCookieKeyPrefix}empty")
    assertNull(request.withDecryptedCookies().header("Cookie"))
  }
}
