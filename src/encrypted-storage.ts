import NativeMxEncryption from './encryption/NativeMxEncryption';

// Legacy API - uses new MxEncryption module under the hood
export const RNMendixEncryptedStorage = {
  getItem: NativeMxEncryption.getItem,
  setItem: NativeMxEncryption.setItem,
  removeItem: NativeMxEncryption.removeItem,
  clear: NativeMxEncryption.clear,
  IS_ENCRYPTED: NativeMxEncryption.isEncrypted(), //This one is constant and not a function hence invoked here
};
