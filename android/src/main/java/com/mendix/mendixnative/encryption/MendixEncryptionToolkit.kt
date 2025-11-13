package com.mendix.mendixnative.encryption

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Base64.DEFAULT
import androidx.annotation.RequiresApi
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.io.IOException
import java.security.GeneralSecurityException
import java.security.Key
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.IvParameterSpec

private const val STORE_AES_KEY = "AES_KEY"
private const val encryptionTransformationName = "AES/CBC/PKCS7Padding"

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
 * generates or returns an application wide AES key.
 *
 * @return Key
 */
@RequiresApi(Build.VERSION_CODES.M)
private fun getAESKey(): Key? {
  val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
  if (!keyStore.containsAlias(STORE_AES_KEY)) {
    val keyGenerator =
      KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
    keyGenerator.init(
      KeyGenParameterSpec.Builder(
        STORE_AES_KEY,
        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
      )
        .setBlockModes(KeyProperties.BLOCK_MODE_CBC)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_PKCS7).build()
    )
    keyGenerator.generateKey()
  }
  return keyStore.getKey(STORE_AES_KEY, null)
}

/**
 * Following best practices from https://developer.android.com/guide/topics/security/cryptography#encrypt-message to encrypt a value.
 *
 * @param value, the value to encrypt
 * @return Triple of Base64 encoded value, Based64 encoded iv, boolean value reflecting if value was encrypted
 */
fun encryptValue(
  value: String,
  @SuppressLint("NewApi", "LocalSuppress") getPassword: () -> Key? = { getAESKey() },
): Triple<ByteArray, ByteArray?, Boolean> {
  val cipher = Cipher.getInstance(encryptionTransformationName)
  cipher.init(Cipher.ENCRYPT_MODE, getPassword())
  val encryptedValue = cipher.doFinal(value.encodeToByteArray())
  return Triple(
    Base64.encode(encryptedValue, DEFAULT),
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
  @SuppressLint("NewApi", "LocalSuppress") getPassword: () -> Key? = { getAESKey() },
): String {
  val cipher = Cipher.getInstance(encryptionTransformationName)
  cipher.init(
    Cipher.DECRYPT_MODE,
    getPassword(),
    IvParameterSpec(Base64.decode(iv, DEFAULT))
  )
  val unencryptedValue = cipher.doFinal(Base64.decode(value, DEFAULT))
  return String(unencryptedValue, Charsets.UTF_8)
}
