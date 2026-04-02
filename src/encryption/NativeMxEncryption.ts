import { TurboModuleRegistry, type TurboModule } from 'react-native';

/**
 * MxEncryption TurboModule
 *
 * Provides secure encrypted storage using platform-native keychains:
 * - iOS: Uses Keychain Services
 * - Android: Uses EncryptedSharedPreferences with AES256
 */
export interface Spec extends TurboModule {
  /**
   * Store an encrypted key-value pair
   * @param key The key to store under
   * @param value The value to encrypt and store
   * @returns Promise that resolves when stored
   */
  setItem(key: string, value: string): Promise<void>;

  /**
   * Retrieve a decrypted value by key
   * @param key The key to retrieve
   * @returns Promise that resolves to the decrypted value, or null if not found
   */
  getItem(key: string): Promise<string | null>;

  /**
   * Remove an encrypted key-value pair
   * @param key The key to remove
   * @returns Promise that resolves when removed
   */
  removeItem(key: string): Promise<void>;

  /**
   * Clear all encrypted storage
   * @returns Promise that resolves when cleared
   */
  clear(): Promise<void>;

  /**
   * Check if storage is encrypted
   * @returns true if encrypted, false otherwise (always true on iOS, may vary on Android)
   */
  isEncrypted(): boolean;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxEncryption');
