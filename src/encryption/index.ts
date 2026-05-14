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
};
