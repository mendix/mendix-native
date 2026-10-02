import { beforeEach, describe, expect, test } from 'react-native-harness';
import {
  MxConfiguration,
  NativeDownloadHandler,
  NativeFileSystem,
} from 'mendix-native';

// The example app's runtime URL points at Metro, which is always up while harness tests run.
const runtimeUrl = MxConfiguration.RUNTIME_URL.replace(/\/$/, '');
const statusUrl = `${runtimeUrl}/status`;

const invalidUrlPath = NativeFileSystem.relativeToDocumentsAbsolutePath(
  'downloads/invalid-url.txt'
);
const downloadPath = NativeFileSystem.relativeToDocumentsAbsolutePath(
  'downloads/status.txt'
);

describe('NativeDownloadHandler', () => {
  beforeEach(async () => {
    for (const path of [invalidUrlPath, downloadPath]) {
      try {
        await NativeFileSystem.remove(path);
      } catch {
        // Cleanup is best-effort.
      }
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
        invalidUrlPath,
        config
      )
    ).rejects.toBeDefined();

    expect(await NativeFileSystem.fileExists(invalidUrlPath)).toBe(false);
  });

  test('does not mutate the config object while rejecting invalid downloads', async () => {
    const config = {
      connectionTimeout: 10,
      mimeType: 'application/json',
    };
    const originalConfig = { ...config };

    await expect(
      NativeDownloadHandler.download('://still-invalid', invalidUrlPath, config)
    ).rejects.toBeDefined();

    expect(config).toEqual(originalConfig);
  });

  test('downloads the response body to the destination path', async () => {
    await NativeDownloadHandler.download(statusUrl, downloadPath, {});

    expect(await NativeFileSystem.readAsText(downloadPath)).toBe(
      'packager-status:running'
    );
  });

  test('rejects an error status without leaving a file behind', async () => {
    await expect(
      NativeDownloadHandler.download(
        `${runtimeUrl}/does-not-exist.txt`,
        downloadPath,
        {}
      )
    ).rejects.toBeDefined();

    expect(await NativeFileSystem.fileExists(downloadPath)).toBe(false);
  });

  test('rejects an unexpected mime type without leaving a file behind', async () => {
    await expect(
      NativeDownloadHandler.download(statusUrl, downloadPath, {
        mimeType: 'application/zip',
      })
    ).rejects.toBeDefined();

    expect(await NativeFileSystem.fileExists(downloadPath)).toBe(false);
  });

  test('rejects when the destination exists and keeps the existing file', async () => {
    await NativeFileSystem.writeJson({ keep: true }, downloadPath);

    await expect(
      NativeDownloadHandler.download(statusUrl, downloadPath, {})
    ).rejects.toBeDefined();

    expect(await NativeFileSystem.readJson(downloadPath)).toEqual({
      keep: true,
    });
  });
});
