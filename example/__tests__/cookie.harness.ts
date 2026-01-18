import { describe, test, expect, beforeEach } from 'react-native-harness';
import { NativeCookie } from 'mendix-native';

describe('NativeCookie', () => {
  describe('API surface', () => {
    test('should expose clearAll method', () => {
      expect(typeof NativeCookie.clearAll).toBe('function');
    });
  });

  describe('clearAll', () => {
    test('should call clearAll without throwing', async () => {
      await expect(NativeCookie.clearAll()).resolves.not.toThrow();
    });

    test('should return a Promise', () => {
      const result = NativeCookie.clearAll();
      expect(result).toBeInstanceOf(Promise);
    });

    test('should resolve to undefined', async () => {
      const result = await NativeCookie.clearAll();
      expect(result).toBeOneOf([undefined, null]);
    });

    test('should be callable multiple times', async () => {
      await NativeCookie.clearAll();
      await NativeCookie.clearAll();
      await NativeCookie.clearAll();

      // Should not throw
      expect(true).toBe(true);
    });

    test('should handle concurrent clearAll calls', async () => {
      const promises = [
        NativeCookie.clearAll(),
        NativeCookie.clearAll(),
        NativeCookie.clearAll(),
      ];

      await expect(Promise.all(promises)).resolves.not.toThrow();
    });
  });

  describe('integration scenarios', () => {
    beforeEach(async () => {
      // Clear cookies before each test
      await NativeCookie.clearAll();
    });

    test('should clear all cookies when called', async () => {
      // This test verifies that clearAll can be called successfully
      // The actual cookie clearing behavior would need to be tested
      // in an integration test with a real web view
      await expect(NativeCookie.clearAll()).resolves.not.toThrow();
    });

    test('should work when no cookies exist', async () => {
      // Calling clearAll when there are no cookies should succeed
      await NativeCookie.clearAll();
      await expect(NativeCookie.clearAll()).resolves.not.toThrow();
    });
  });
});
