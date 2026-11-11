package com.mendix.mendixnative.encryption

import android.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.IvParameterSpec

// Robolectric provides android.util.Base64; keys are software keys since there is no AndroidKeyStore.
@RunWith(RobolectricTestRunner::class)
class MendixEncryptionToolkitTest {
  private fun aesKey() = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()

  @Test
  fun encryptDecryptRoundTrip() {
    val key = aesKey()
    val (value, iv, encrypted) = encryptValue("séssion=1; x") { key }

    assertTrue(encrypted)
    assertTrue(value.decodeToString().startsWith("v2:"))
    assertEquals(
      "séssion=1; x",
      decryptValue(value.decodeToString(), iv!!.decodeToString(), modernGetPassword = { key })
    )
  }

  @Test
  fun encryptUsesFreshIvEachTime() {
    val key = aesKey()
    val first = encryptValue("value") { key }
    val second = encryptValue("value") { key }

    assertNotEquals(first.second!!.decodeToString(), second.second!!.decodeToString())
    assertNotEquals(first.first.decodeToString(), second.first.decodeToString())
  }

  @Test
  fun decryptWithWrongKeyFails() {
    val (value, iv) = encryptValue("value") { aesKey() }
    val wrongKey = aesKey()

    assertThrows(AEADBadTagException::class.java) {
      decryptValue(value.decodeToString(), iv!!.decodeToString(), modernGetPassword = { wrongKey })
    }
  }

  @Test
  fun decryptRequiresIv() {
    val (value) = encryptValue("value") { aesKey() }

    assertThrows(IllegalArgumentException::class.java) {
      decryptValue(value.decodeToString(), null, modernGetPassword = { aesKey() })
    }
  }

  @Test
  fun decryptsLegacyCbcValues() {
    val key = aesKey()
    val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding").apply { init(Cipher.ENCRYPT_MODE, key) }
    val encrypted = Base64.encodeToString(cipher.doFinal("legacy".toByteArray()), Base64.DEFAULT)
    val iv = Base64.encodeToString((cipher.parameters.getParameterSpec(IvParameterSpec::class.java)).iv, Base64.DEFAULT)

    assertEquals("legacy", decryptValue(encrypted, iv, legacyGetPassword = { key }))
  }
}
