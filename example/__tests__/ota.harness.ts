import { describe, test, expect } from 'react-native-harness';
import { MxConfiguration, NativeOta } from 'mendix-native';

// The example app's runtime URL points at Metro, which is always up while harness tests run.
const runtimeUrl = MxConfiguration.RUNTIME_URL.replace(/\/$/, '');

describe('NativeOta', () => {
  describe('download', () => {
    test('rejects URLs outside the runtime URL', async () => {
      await expect(
        NativeOta.download({ url: 'https://example.invalid/ota.zip' })
      ).rejects.toMatchObject({ code: 'INVALID_RUNTIME_URL' });
    });

    test('downloads from the runtime URL and returns a zip file name', async () => {
      const { otaPackage } = await NativeOta.download({
        url: `${runtimeUrl}/status`,
      });

      expect(otaPackage).toMatch(/\.zip$/);
    });

    test('rejects when the runtime URL returns an error status', async () => {
      await expect(
        NativeOta.download({ url: `${runtimeUrl}/does-not-exist.zip` })
      ).rejects.toMatchObject({ code: 'OTA_DOWNLOAD_FAILED' });
    });
  });

  describe('deploy', () => {
    test('rejects when the OTA package does not exist', async () => {
      await expect(
        NativeOta.deploy({
          otaDeploymentID: 'harness-missing-package',
          otaPackage: 'does-not-exist.zip',
          extractionDir: 'harness-missing-package',
        })
      ).rejects.toMatchObject({ code: 'OTA_ZIP_FILE_MISSING' });
    });

    test('rejects a config with a missing key', async () => {
      await expect(
        NativeOta.deploy({
          otaPackage: 'does-not-exist.zip',
          extractionDir: 'harness-missing-key',
        } as unknown as Parameters<typeof NativeOta.deploy>[0])
      ).rejects.toMatchObject({ code: 'INVALID_DEPLOY_CONFIG' });
    });

    test('rejects paths outside the OTA directory', async () => {
      await expect(
        NativeOta.deploy({
          otaDeploymentID: 'harness-escape',
          otaPackage: 'does-not-exist.zip',
          extractionDir: '../escape',
        })
      ).rejects.toMatchObject({ code: 'INVALID_DEPLOY_CONFIG' });

      await expect(
        NativeOta.deploy({
          otaDeploymentID: 'harness-escape',
          otaPackage: '../does-not-exist.zip',
          extractionDir: 'harness-escape',
        })
      ).rejects.toMatchObject({ code: 'INVALID_DEPLOY_CONFIG' });
    });

    test('rejects a downloaded package that is not a valid zip', async () => {
      // Metro's status endpoint returns plain text, so the "package" can't be unzipped.
      const { otaPackage } = await NativeOta.download({
        url: `${runtimeUrl}/status`,
      });

      await expect(
        NativeOta.deploy({
          otaDeploymentID: 'harness-invalid-zip',
          otaPackage,
          extractionDir: 'harness-invalid-zip',
        })
      ).rejects.toMatchObject({ code: 'OTA_DEPLOYMENT_FAILED' });
    });
  });
});
