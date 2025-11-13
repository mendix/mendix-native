import Mx from './specs/NativeMendixNative';

export const RNMendixEncryptedStorage = {
  getItem: Mx.encryptedStorageGetItem,
  setItem: Mx.encryptedStorageSetItem,
  removeItem: Mx.encryptedStorageRemoveItem,
  clear: Mx.encryptedStorageClear,
  IS_ENCRYPTED: Mx.encryptedStorageIsEncrypted(), //This one is constant and not a function hence invoked here
};
