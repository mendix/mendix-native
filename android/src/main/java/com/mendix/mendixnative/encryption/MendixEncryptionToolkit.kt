package com.mendix.mendixnative.encryption

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Base64.DEFAULT
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.io.IOException
import java.security.GeneralSecurityException
import java.security.Key
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.IvParameterSpec

private const val STORE_AES_KEY = "AES_KEY"
private const val STORE_AES_KEY_V2 = "AES_KEY_V2"
private const val legacyEncryptionTransformationName = "AES/CBC/PKCS7Padding"
private const val modernEncryptionTransformationName = "AES/GCM/NoPadding"
private const val modernEncryptionVersionPrefix = "v2:"
private const val gcmTagLengthBits = 128

private var masterKey: MasterKey? = null
fun getMasterKey(context: Context): MasterKey {
  if (masterKey == null) {
    masterKey = MasterKey.Builder(context)
      .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
      .build()
  }
  return masterKey!!
}

@Throws(GeneralSecurityException::class, IOException::class)
fun getEncryptedSharedPreferences(
  context: Context,
  key: MasterKey,
  prefName: String,
): SharedPreferences {
  return EncryptedSharedPreferences.create(
    context,
    prefName,
    key,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
  )
}

/**
 * returns an application wide AES key.
 *
 * @return Key
 */
private fun getAESKey(): Key? {
  val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
  return if (keyStore.containsAlias(STORE_AES_KEY))
    keyStore.getKey(STORE_AES_KEY, null)
  else null
}

private fun getAESKeyV2(): Key? {
  return getOrCreateAESKey(
    STORE_AES_KEY_V2,
    KeyProperties.BLOCK_MODE_GCM,
    KeyProperties.ENCRYPTION_PADDING_NONE
  )
}

private fun getOrCreateAESKey(alias: String, blockMode: String, encryptionPadding: String): Key? {
  val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
  if (!keyStore.containsAlias(alias)) {
    val keyGenerator =
      KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
    keyGenerator.init(
      KeyGenParameterSpec.Builder(
        alias,
        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
      )
        .setBlockModes(blockMode)
        .setEncryptionPaddings(encryptionPadding).build()
    )
    keyGenerator.generateKey()
  }
  return keyStore.getKey(alias, null)
}

/**
 * Following best practices from https://developer.android.com/guide/topics/security/cryptography#encrypt-message to encrypt a value.
 *
 * @param value, the value to encrypt
 * @return Triple of Base64 encoded value, Based64 encoded iv, boolean value reflecting if value was encrypted
 */
fun encryptValue(
  value: String,
  @SuppressLint("NewApi", "LocalSuppress") getPassword: () -> Key? = { getAESKeyV2() },
): Triple<ByteArray, ByteArray?, Boolean> {
  val cipher = Cipher.getInstance(modernEncryptionTransformationName)
  cipher.init(Cipher.ENCRYPT_MODE, getPassword())
  val encryptedValue = cipher.doFinal(value.encodeToByteArray())
  val versionedEncryptedValue =
    "$modernEncryptionVersionPrefix${Base64.encodeToString(encryptedValue, DEFAULT)}"
  return Triple(
    versionedEncryptedValue.encodeToByteArray(),
    Base64.encode(cipher.iv, DEFAULT),
    true
  )
}

/**
 * Decrypts a base64 encoded and possibly AES encrypted value using the provided initialization value
 *
 * @param value, Base64 encoded string
 * @param iv, Base64 encoded value of the IV used when encrypting the value
 * @return unencrypted value
 */
fun decryptValue(
  value: String,
  iv: String?,
  @SuppressLint("NewApi", "LocalSuppress") legacyGetPassword: () -> Key? = { getAESKey() },
  @SuppressLint("NewApi", "LocalSuppress") modernGetPassword: () -> Key? = { getAESKeyV2() },
): String {
  return if (value.startsWith(modernEncryptionVersionPrefix)) {
    decryptModernValue(value.removePrefix(modernEncryptionVersionPrefix), iv, modernGetPassword)
  } else {
    decryptLegacyValue(value, iv, legacyGetPassword)
  }
}

private fun decryptLegacyValue(
  value: String,
  iv: String?,
  getPassword: () -> Key?,
): String {
  requireNotNull(iv) { "Missing IV for legacy encrypted value." }
  val cipher = Cipher.getInstance(legacyEncryptionTransformationName)
  cipher.init(
    Cipher.DECRYPT_MODE,
    getPassword(),
    IvParameterSpec(Base64.decode(iv, DEFAULT))
  )
  val unencryptedValue = cipher.doFinal(Base64.decode(value, DEFAULT))
  return String(unencryptedValue, Charsets.UTF_8)
}

private fun decryptModernValue(
  value: String,
  iv: String?,
  getPassword: () -> Key?,
): String {
  requireNotNull(iv) { "Missing nonce for modern encrypted value." }
  val cipher = Cipher.getInstance(modernEncryptionTransformationName)
  cipher.init(
    Cipher.DECRYPT_MODE,
    getPassword(),
    GCMParameterSpec(gcmTagLengthBits, Base64.decode(iv, DEFAULT))
  )
  val unencryptedValue = cipher.doFinal(Base64.decode(value, DEFAULT))
  return String(unencryptedValue, Charsets.UTF_8)
}
