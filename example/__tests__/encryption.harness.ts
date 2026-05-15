import { beforeEach, describe, expect, test } from 'react-native-harness';
import { MxEncryption, RNMendixEncryptedStorage } from 'mendix-native';

describe('MxEncryption', () => {
  beforeEach(async () => {
    await MxEncryption.clear();
  });

  test('stores and retrieves values through the modern API', async () => {
    await MxEncryption.setItem('modern-key', 'modern-value');

    await expect(MxEncryption.getItem('modern-key')).resolves.toBe(
      'modern-value'
    );
  });

  test('shares the same backing store as the legacy encrypted storage API', async () => {
    await MxEncryption.setItem('shared-key', 'set-by-modern');
    await expect(RNMendixEncryptedStorage.getItem('shared-key')).resolves.toBe(
      'set-by-modern'
    );

    await RNMendixEncryptedStorage.setItem('shared-key', 'set-by-legacy');
    await expect(MxEncryption.getItem('shared-key')).resolves.toBe(
      'set-by-legacy'
    );
  });

  test('removeItem is visible across both exported wrappers', async () => {
    await RNMendixEncryptedStorage.setItem('cross-remove-key', 'value');

    await MxEncryption.removeItem('cross-remove-key');

    await expect(
      RNMendixEncryptedStorage.getItem('cross-remove-key')
    ).resolves.toBe(null);
  });

  test('isEncrypted matches the legacy constant contract', () => {
    expect(MxEncryption.isEncrypted()).toBe(
      RNMendixEncryptedStorage.IS_ENCRYPTED
    );
  });
});
