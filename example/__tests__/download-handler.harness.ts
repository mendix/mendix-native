import { beforeEach, describe, expect, test } from 'react-native-harness';
import { NativeDownloadHandler, NativeFileSystem } from 'mendix-native';

const downloadPath = NativeFileSystem.relativeToDocumentsAbsolutePath(
  'downloads/invalid-url.txt'
);

describe('NativeDownloadHandler', () => {
  beforeEach(async () => {
    try {
      await NativeFileSystem.remove(downloadPath);
    } catch {
      // Cleanup is best-effort.
    }
  });

  test('rejects malformed URLs without creating a destination file', async () => {
    const config = {
      connectionTimeout: 25,
      mimeType: 'text/plain',
    };

    await expect(
      NativeDownloadHandler.download(
        '://definitely-invalid-url',
        downloadPath,
        config
      )
    ).rejects.toBeDefined();

    expect(await NativeFileSystem.fileExists(downloadPath)).toBe(false);
  });

  test('does not mutate the config object while rejecting invalid downloads', async () => {
    const config = {
      connectionTimeout: 10,
      mimeType: 'application/json',
    };
    const originalConfig = { ...config };

    await expect(
      NativeDownloadHandler.download('://still-invalid', downloadPath, config)
    ).rejects.toBeDefined();

    expect(config).toEqual(originalConfig);
  });
});
