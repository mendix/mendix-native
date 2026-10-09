package com.mendix.mendixnative.config

import org.junit.Assert.assertEquals
import org.junit.Test

class AppUrlTest {
  @Test
  fun forRuntimeAddsProtocolAndTrailingSlash() {
    assertEquals("http://example.com/", AppUrl.forRuntime("example.com"))
    assertEquals("https://example.com/", AppUrl.forRuntime("https://example.com/"))
    assertEquals("http://10.0.2.2:8080/", AppUrl.forRuntime("http://10.0.2.2:8080"))
  }

  @Test
  fun forRuntimeKeepsSubpath() {
    assertEquals("https://example.com/app/", AppUrl.forRuntime("https://example.com/app"))
  }

  @Test
  fun ensureProtocolOnlyAcceptsHttpSchemes() {
    assertEquals("https://example.com", AppUrl.ensureProtocol("https://example.com"))
    assertEquals("http://ftp://example.com", AppUrl.ensureProtocol("ftp://example.com"))
  }

  @Test
  fun removeTrailingSlashRemovesOneSlash() {
    assertEquals("http://example.com", AppUrl.removeTrailingSlash("http://example.com/"))
    assertEquals("http://example.com", AppUrl.removeTrailingSlash("http://example.com"))
  }

  @Test
  fun forBundleJoinsHostAndPort() {
    assertEquals("localhost:8081", AppUrl.forBundle("localhost", 8081))
  }
}
