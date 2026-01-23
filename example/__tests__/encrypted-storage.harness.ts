import { describe, test, expect, beforeEach } from 'react-native-harness';
import { RNMendixEncryptedStorage } from 'mendix-native';

describe('RNMendixEncryptedStorage', () => {
  beforeEach(async () => {
    // Clear storage before each test
    await RNMendixEncryptedStorage.clear();
  });

  describe('setItem and getItem', () => {
    test('should store and retrieve a string value', async () => {
      const key = 'testKey';
      const value = 'testValue';

      await RNMendixEncryptedStorage.setItem(key, value);
      const retrievedValue = await RNMendixEncryptedStorage.getItem(key);

      expect(retrievedValue).toBe(value);
    });

    test('should store and retrieve multiple key-value pairs', async () => {
      await RNMendixEncryptedStorage.setItem('key1', 'value1');
      await RNMendixEncryptedStorage.setItem('key2', 'value2');
      await RNMendixEncryptedStorage.setItem('key3', 'value3');

      const value1 = await RNMendixEncryptedStorage.getItem('key1');
      const value2 = await RNMendixEncryptedStorage.getItem('key2');
      const value3 = await RNMendixEncryptedStorage.getItem('key3');

      expect(value1).toBe('value1');
      expect(value2).toBe('value2');
      expect(value3).toBe('value3');
    });

    test('should return null for non-existent key', async () => {
      const value = await RNMendixEncryptedStorage.getItem('nonExistentKey');
      expect(value).toBe(null);
    });

    test('should update existing value when setting same key', async () => {
      const key = 'updateKey';

      await RNMendixEncryptedStorage.setItem(key, 'initialValue');
      await RNMendixEncryptedStorage.setItem(key, 'updatedValue');

      const value = await RNMendixEncryptedStorage.getItem(key);
      expect(value).toBe('updatedValue');
    });

    test('should handle empty string values', async () => {
      await RNMendixEncryptedStorage.setItem('emptyKey', '');
      const value = await RNMendixEncryptedStorage.getItem('emptyKey');
      expect(value).toBe('');
    });

    test('should handle special characters in keys and values', async () => {
      const specialKey = 'key-with-special!@#$%^&*()chars';
      const specialValue = 'value with emoji 🔐 and symbols !@#$%';

      await RNMendixEncryptedStorage.setItem(specialKey, specialValue);
      const value = await RNMendixEncryptedStorage.getItem(specialKey);

      expect(value).toBe(specialValue);
    });

    test('should handle JSON stringified objects', async () => {
      const obj = { name: 'John', age: 30, active: true };
      const jsonString = JSON.stringify(obj);

      await RNMendixEncryptedStorage.setItem('jsonKey', jsonString);
      const retrieved = await RNMendixEncryptedStorage.getItem('jsonKey');

      expect(retrieved).toBe(jsonString);
      expect(JSON.parse(retrieved!)).toEqual(obj);
    });
  });

  describe('removeItem', () => {
    test('should remove an existing item', async () => {
      await RNMendixEncryptedStorage.setItem('removeKey', 'removeValue');
      await RNMendixEncryptedStorage.removeItem('removeKey');

      const value = await RNMendixEncryptedStorage.getItem('removeKey');
      expect(value).toBe(null);
    });

    test('should not throw error when removing non-existent item', async () => {
      await expect(
        RNMendixEncryptedStorage.removeItem('nonExistentKey')
      ).resolves.not.toThrow();
    });

    test('should only remove specified item', async () => {
      await RNMendixEncryptedStorage.setItem('key1', 'value1');
      await RNMendixEncryptedStorage.setItem('key2', 'value2');

      await RNMendixEncryptedStorage.removeItem('key1');

      const value1 = await RNMendixEncryptedStorage.getItem('key1');
      const value2 = await RNMendixEncryptedStorage.getItem('key2');

      expect(value1).toBe(null);
      expect(value2).toBe('value2');
    });
  });

  describe('clear', () => {
    test('should clear all stored items', async () => {
      await RNMendixEncryptedStorage.setItem('key1', 'value1');
      await RNMendixEncryptedStorage.setItem('key2', 'value2');
      await RNMendixEncryptedStorage.setItem('key3', 'value3');

      await RNMendixEncryptedStorage.clear();

      const value1 = await RNMendixEncryptedStorage.getItem('key1');
      const value2 = await RNMendixEncryptedStorage.getItem('key2');
      const value3 = await RNMendixEncryptedStorage.getItem('key3');

      expect(value1).toBe(null);
      expect(value2).toBe(null);
      expect(value3).toBe(null);
    });

    test('should work on empty storage', async () => {
      await expect(RNMendixEncryptedStorage.clear()).resolves.not.toThrow();
    });

    test('should allow new items after clear', async () => {
      await RNMendixEncryptedStorage.setItem('beforeClear', 'value');
      await RNMendixEncryptedStorage.clear();
      await RNMendixEncryptedStorage.setItem('afterClear', 'newValue');

      const value = await RNMendixEncryptedStorage.getItem('afterClear');
      expect(value).toBe('newValue');
    });
  });

  describe('IS_ENCRYPTED property', () => {
    test('should have IS_ENCRYPTED as a boolean', () => {
      expect(typeof RNMendixEncryptedStorage.IS_ENCRYPTED).toBe('boolean');
    });

    test('should be a constant value (not a function)', () => {
      const firstValue = RNMendixEncryptedStorage.IS_ENCRYPTED;
      const secondValue = RNMendixEncryptedStorage.IS_ENCRYPTED;
      expect(firstValue).toBe(secondValue);
    });
  });

  describe('concurrent operations', () => {
    test('should handle concurrent setItem operations', async () => {
      await Promise.all([
        RNMendixEncryptedStorage.setItem('concurrent1', 'value1'),
        RNMendixEncryptedStorage.setItem('concurrent2', 'value2'),
        RNMendixEncryptedStorage.setItem('concurrent3', 'value3'),
      ]);

      const [value1, value2, value3] = await Promise.all([
        RNMendixEncryptedStorage.getItem('concurrent1'),
        RNMendixEncryptedStorage.getItem('concurrent2'),
        RNMendixEncryptedStorage.getItem('concurrent3'),
      ]);

      expect(value1).toBe('value1');
      expect(value2).toBe('value2');
      expect(value3).toBe('value3');
    });

    test('should handle concurrent getItem operations', async () => {
      await RNMendixEncryptedStorage.setItem('shared', 'sharedValue');

      const results = await Promise.all([
        RNMendixEncryptedStorage.getItem('shared'),
        RNMendixEncryptedStorage.getItem('shared'),
        RNMendixEncryptedStorage.getItem('shared'),
      ]);

      results.forEach((result) => {
        expect(result).toBe('sharedValue');
      });
    });
  });
});
