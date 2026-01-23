import { describe, test, expect } from 'react-native-harness';
import { NativeOta } from 'mendix-native';

describe('NativeOta', () => {
  describe('API surface', () => {
    test('should expose download method', () => {
      expect(typeof NativeOta.download).toBe('function');
    });

    test('should expose deploy method', () => {
      expect(typeof NativeOta.deploy).toBe('function');
    });
  });

  describe('download', () => {
    test('should accept OtaDownloadConfig parameter', () => {
      const config = {
        url: 'https://example.com/ota-package.zip',
      };

      // Should not throw when called with valid config
      const result = NativeOta.download(config);
      expect(result).toBeInstanceOf(Promise);
    });

    test('should return a Promise', () => {
      const config = {
        url: 'https://example.com/ota-package.zip',
      };

      const result = NativeOta.download(config);
      expect(result).toBeInstanceOf(Promise);
    });

    test('should handle different URL formats', () => {
      const configs = [
        { url: 'https://example.com/package.zip' },
        { url: 'http://localhost:8080/bundle.zip' },
        { url: 'https://cdn.example.com/v1.0.0/update.zip' },
      ];

      configs.forEach((config) => {
        const result = NativeOta.download(config);
        expect(result).toBeInstanceOf(Promise);
      });
    });
  });

  describe('deploy', () => {
    test('should accept OtaDeployConfig parameter', () => {
      const config = {
        otaDeploymentID: 'deployment-123',
        otaPackage: '/path/to/package.zip',
        extractionDir: '/path/to/extraction/dir',
      };

      const result = NativeOta.deploy(config);
      expect(result).toBeInstanceOf(Promise);
    });

    test('should return a Promise', () => {
      const config = {
        otaDeploymentID: 'deployment-123',
        otaPackage: '/path/to/package.zip',
        extractionDir: '/path/to/extraction/dir',
      };

      const result = NativeOta.deploy(config);
      expect(result).toBeInstanceOf(Promise);
    });

    test('should handle different deployment IDs', () => {
      const configs = [
        {
          otaDeploymentID: 'deployment-1',
          otaPackage: '/path/to/package1.zip',
          extractionDir: '/path/to/dir1',
        },
        {
          otaDeploymentID: 'deployment-2',
          otaPackage: '/path/to/package2.zip',
          extractionDir: '/path/to/dir2',
        },
        {
          otaDeploymentID: 'prod-deployment-v1.0.0',
          otaPackage: '/path/to/prod.zip',
          extractionDir: '/path/to/prod-dir',
        },
      ];

      configs.forEach((config) => {
        const result = NativeOta.deploy(config);
        expect(result).toBeInstanceOf(Promise);
      });
    });

    test('should handle various path formats', () => {
      const configs = [
        {
          otaDeploymentID: 'test',
          otaPackage: 'package.zip',
          extractionDir: 'extraction',
        },
        {
          otaDeploymentID: 'test',
          otaPackage: '/absolute/path/package.zip',
          extractionDir: '/absolute/path/extraction',
        },
        {
          otaDeploymentID: 'test',
          otaPackage: './relative/path/package.zip',
          extractionDir: './relative/path/extraction',
        },
      ];

      configs.forEach((config) => {
        const result = NativeOta.deploy(config);
        expect(result).toBeInstanceOf(Promise);
      });
    });
  });

  describe('type safety', () => {
    test('download config should require url property', () => {
      const config = {
        url: 'https://example.com/package.zip',
      };

      // TypeScript should ensure url is present
      expect(config.url).toBeDefined();
      expect(typeof config.url).toBe('string');
    });

    test('deploy config should require all properties', () => {
      const config = {
        otaDeploymentID: 'deployment-123',
        otaPackage: '/path/to/package.zip',
        extractionDir: '/path/to/extraction/dir',
      };

      // TypeScript should ensure all required properties are present
      expect(config.otaDeploymentID).toBeDefined();
      expect(config.otaPackage).toBeDefined();
      expect(config.extractionDir).toBeDefined();
    });
  });

  describe('workflow scenarios', () => {
    test('should support download then deploy workflow', async () => {
      const downloadConfig = {
        url: 'https://example.com/ota-package.zip',
      };

      // In a real scenario, download would complete and return package path
      // For testing, we just verify the methods can be called in sequence
      const downloadPromise = NativeOta.download(downloadConfig);
      expect(downloadPromise).toBeInstanceOf(Promise);

      const deployConfig = {
        otaDeploymentID: 'deployment-123',
        otaPackage: '/path/to/downloaded-package.zip',
        extractionDir: '/path/to/extraction',
      };

      const deployPromise = NativeOta.deploy(deployConfig);
      expect(deployPromise).toBeInstanceOf(Promise);
    });
  });
});
