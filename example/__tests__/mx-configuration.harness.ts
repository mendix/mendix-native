import { describe, test, expect } from 'react-native-harness';
import { MxConfiguration } from 'mendix-native';

describe('MxConfiguration', () => {
  describe('Configuration object', () => {
    test('should be defined', () => {
      expect(MxConfiguration).toBeDefined();
    });

    test('should be an object', () => {
      expect(typeof MxConfiguration).toBe('object');
    });

    test('should not be null', () => {
      expect(MxConfiguration).not.toBe(null);
    });
  });

  describe('Required properties', () => {
    test('should have RUNTIME_URL', () => {
      expect(MxConfiguration).toHaveProperty('RUNTIME_URL');
      expect(typeof MxConfiguration.RUNTIME_URL).toBe('string');
    });

    test('should have APP_NAME', () => {
      expect(MxConfiguration).toHaveProperty('APP_NAME');
      // APP_NAME can be string or null
      const appName = MxConfiguration.APP_NAME;
      expect(appName === null || typeof appName === 'string').toBe(true);
    });

    test('should have DATABASE_NAME', () => {
      expect(MxConfiguration).toHaveProperty('DATABASE_NAME');
      expect(typeof MxConfiguration.DATABASE_NAME).toBe('string');
    });

    test('should have WARNINGS_FILTER_LEVEL', () => {
      expect(MxConfiguration).toHaveProperty('WARNINGS_FILTER_LEVEL');
      expect(typeof MxConfiguration.WARNINGS_FILTER_LEVEL).toBe('string');
    });

    test('should have OTA_MANIFEST_PATH', () => {
      expect(MxConfiguration).toHaveProperty('OTA_MANIFEST_PATH');
      expect(typeof MxConfiguration.OTA_MANIFEST_PATH).toBe('string');
    });
  });

  describe('Optional properties', () => {
    test('may have NATIVE_DEPENDENCIES', () => {
      if ('NATIVE_DEPENDENCIES' in MxConfiguration) {
        const deps = MxConfiguration.NATIVE_DEPENDENCIES;
        if (deps !== undefined) {
          expect(typeof deps).toBe('object');
        }
      }
    });

    test('may have IS_DEVELOPER_APP', () => {
      if ('IS_DEVELOPER_APP' in MxConfiguration) {
        const isDev = MxConfiguration.IS_DEVELOPER_APP;
        if (isDev !== undefined) {
          expect(typeof isDev).toBe('boolean');
        }
      }
    });

    test('may have NATIVE_BINARY_VERSION', () => {
      if ('NATIVE_BINARY_VERSION' in MxConfiguration) {
        const version = MxConfiguration.NATIVE_BINARY_VERSION;
        if (version !== undefined) {
          expect(typeof version).toBe('number');
        }
      }
    });

    test('may have APP_SESSION_ID', () => {
      if ('APP_SESSION_ID' in MxConfiguration) {
        const sessionId = MxConfiguration.APP_SESSION_ID;
        if (sessionId != null) {
          expect(typeof sessionId).toBe('string');
        }
      }
    });
  });

  describe('Property values', () => {
    test('RUNTIME_URL should not be empty', () => {
      expect(MxConfiguration.RUNTIME_URL.length).toBeGreaterThan(0);
    });

    test('DATABASE_NAME should not be empty', () => {
      expect(MxConfiguration.DATABASE_NAME.length).toBeGreaterThan(0);
    });

    test('WARNINGS_FILTER_LEVEL should be valid', () => {
      const level = MxConfiguration.WARNINGS_FILTER_LEVEL.toLowerCase();
      // We don't enforce specific values but ensure it's not empty
      expect(level.length).toBeGreaterThan(0);
    });

    test('OTA_MANIFEST_PATH should not be empty', () => {
      expect(MxConfiguration.OTA_MANIFEST_PATH.length).toBeGreaterThan(0);
    });
  });

  describe('Immutability', () => {
    test('should be the same object on multiple accesses', () => {
      const config1 = MxConfiguration;
      const config2 = MxConfiguration;
      expect(config1).toBe(config2);
    });

    test('should have consistent property values', () => {
      const runtimeUrl1 = MxConfiguration.RUNTIME_URL;
      const runtimeUrl2 = MxConfiguration.RUNTIME_URL;
      expect(runtimeUrl1).toBe(runtimeUrl2);
    });
  });

  describe('Type structure', () => {
    test('should match expected configuration structure', () => {
      const config = MxConfiguration;

      // Required fields
      expect(config).toHaveProperty('RUNTIME_URL');
      expect(config).toHaveProperty('APP_NAME');
      expect(config).toHaveProperty('DATABASE_NAME');
      expect(config).toHaveProperty('WARNINGS_FILTER_LEVEL');
      expect(config).toHaveProperty('OTA_MANIFEST_PATH');
    });
  });

  describe('Native dependencies', () => {
    test('NATIVE_DEPENDENCIES should be object if present', () => {
      if (MxConfiguration.NATIVE_DEPENDENCIES) {
        expect(typeof MxConfiguration.NATIVE_DEPENDENCIES).toBe('object');

        // If present, should be key-value pairs of strings
        Object.entries(MxConfiguration.NATIVE_DEPENDENCIES).forEach(
          ([key, value]) => {
            expect(typeof key).toBe('string');
            expect(typeof value).toBe('string');
          }
        );
      }
    });
  });
});
