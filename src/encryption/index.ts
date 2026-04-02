import NativeMxEncryption from './NativeMxEncryption';

/**
 * MxEncryption - Secure encrypted storage
 *
 * Provides a simple key-value store with automatic encryption using platform-native APIs:
 * - iOS: Keychain Services
 * - Android: EncryptedSharedPreferences (AES256-GCM)
 *
 * @example
 * ```typescript
 * import { MxEncryption } from 'mendix-native';
 *
 * // Store encrypted data
 * await MxEncryption.setItem('auth_token', 'secret123');
 *
 * // Retrieve decrypted data
 * const token = await MxEncryption.getItem('auth_token');
 *
 * // Remove item
 * await MxEncryption.removeItem('auth_token');
 *
 * // Clear all encrypted storage
 * await MxEncryption.clear();
 *
 * // Check if encrypted
 * const encrypted = MxEncryption.isEncrypted(); // true
 * ```
 */
export const MxEncryption = {
  /**
   * Store an encrypted key-value pair
   * @param key The key to store under
   * @param value The value to encrypt and store
   * @returns Promise that resolves when stored
   */
  async setItem(key: string, value: string): Promise<void> {
    return NativeMxEncryption.setItem(key, value);
  },

  /**
   * Retrieve a decrypted value by key
   * @param key The key to retrieve
   * @returns Promise that resolves to the decrypted value, or null if not found
   */
  async getItem(key: string): Promise<string | null> {
    return NativeMxEncryption.getItem(key);
  },

  /**
   * Remove an encrypted key-value pair
   * @param key The key to remove
   * @returns Promise that resolves when removed
   */
  async removeItem(key: string): Promise<void> {
    return NativeMxEncryption.removeItem(key);
  },

  /**
   * Clear all encrypted storage
   * @returns Promise that resolves when cleared
   */
  async clear(): Promise<void> {
    return NativeMxEncryption.clear();
  },

  /**
   * Check if storage is encrypted
   * @returns true if encrypted, false otherwise (always true on iOS, may vary on Android)
   */
  isEncrypted(): boolean {
    return NativeMxEncryption.isEncrypted();
  },
};
