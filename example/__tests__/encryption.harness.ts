import { beforeEach, describe, expect, test } from 'react-native-harness';
import { MxEncryption, RNMendixEncryptedStorage } from 'mendix-native';
import { Platform } from 'react-native';
import { getKeychainTestSupport } from '../test-support/keychain';

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

  test('strict reads return stored values and null for missing keys', async () => {
    await expect(MxEncryption.getItemStrict('missing')).resolves.toBe(null);
    await MxEncryption.setItem('strict-key', 'value');
    await expect(MxEncryption.getItemStrict('strict-key')).resolves.toBe(
      'value'
    );
  });

  if (Platform.OS === 'ios') {
    test('new writes use device-only after-first-unlock accessibility', async () => {
      await MxEncryption.setItem('policy-key', 'value');
      const attributes =
        await getKeychainTestSupport().inspectItem('policy-key');
      expect(attributes).not.toBe(null);
      expect(attributes?.accessibility).toBe(attributes?.expectedAccessibility);
    });

    test('strict reads migrate legacy values without rotating them', async () => {
      const support = getKeychainTestSupport();
      await support.seedLegacyItem('legacy-strict-key', 'original-password');
      const before = await support.inspectItem('legacy-strict-key');
      expect(before?.accessibility).toBe(before?.legacyAccessibility);
      await expect(
        MxEncryption.getItemStrict('legacy-strict-key')
      ).resolves.toBe('original-password');
      const after = await support.inspectItem('legacy-strict-key');
      expect(after).not.toBe(null);
      expect(after?.accessibility).toBe(after?.expectedAccessibility);
      await expect(MxEncryption.getItem('legacy-strict-key')).resolves.toBe(
        'original-password'
      );
    });
  }
});
