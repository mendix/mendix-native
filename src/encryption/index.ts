import NativeMxEncryption from './NativeMxEncryption';

export const MxEncryption = {
  async setItem(key: string, value: string): Promise<void> {
    return NativeMxEncryption.setItem(key, value);
  },
  async getItem(key: string): Promise<string | null> {
    return NativeMxEncryption.getItem(key);
  },
  async removeItem(key: string): Promise<void> {
    return NativeMxEncryption.removeItem(key);
  },
  async clear(): Promise<void> {
    return NativeMxEncryption.clear();
  },
  isEncrypted(): boolean {
    return NativeMxEncryption.isEncrypted();
  },
  /**
   * Returns `byteLength` bytes from the platform's cryptographically secure random generator
   * (SecRandomCopyBytes on iOS, SecureRandom on Android), lowercase hex encoded
   * (2 characters per byte). Throws if `byteLength` is not an integer between 1 and 1024,
   * or if the secure generator fails. It never falls back to a weaker source.
   */
  getRandomHex(byteLength: number): string {
    return NativeMxEncryption.getRandomHex(byteLength);
  },
};
