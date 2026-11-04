import { Platform } from 'react-native';
import { beforeEach, describe, expect, test } from 'react-native-harness';
import {
  MxConfiguration,
  NativeDownloadHandler,
  NativeFileSystem,
} from 'mendix-native';

// The example app's runtime URL points at Metro, which is always up while harness tests run.
const runtimeUrl = MxConfiguration.RUNTIME_URL.replace(/\/$/, '');
// Sent without a Content-Type.
const statusUrl = `${runtimeUrl}/status`;
// A small bundle, sent as "application/javascript; charset=UTF-8".
const bundleUrl = `${runtimeUrl}/index.bundle?platform=${Platform.OS}&dev=true&minify=false&shallow=true&modulesOnly=true&runModule=false`;

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
    ).rejects.toMatchObject({ code: 'ERROR_DOWNLOAD_FAILED' });

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
    ).rejects.toMatchObject({ code: 'ERROR_DOWNLOAD_FAILED' });

    expect(await NativeFileSystem.fileExists(downloadPath)).toBe(false);
  });

  test('rejects an unexpected mime type without leaving a file behind', async () => {
    await expect(
      NativeDownloadHandler.download(bundleUrl, downloadPath, {
        mimeType: 'application/zip',
      })
    ).rejects.toMatchObject({ code: 'ERROR_DOWNLOAD_FAILED' });

    expect(await NativeFileSystem.fileExists(downloadPath)).toBe(false);
  });

  test('accepts a mime type whose response has parameters', async () => {
    await NativeDownloadHandler.download(bundleUrl, downloadPath, {
      mimeType: 'application/javascript',
    });

    expect(await NativeFileSystem.fileExists(downloadPath)).toBe(true);
  });

  test('rejects a response without a content type when a mime type is expected', async () => {
    await expect(
      NativeDownloadHandler.download(statusUrl, downloadPath, {
        mimeType: 'text/plain',
      })
    ).rejects.toMatchObject({ code: 'ERROR_DOWNLOAD_FAILED' });

    expect(await NativeFileSystem.fileExists(downloadPath)).toBe(false);
  });

  test('rejects when the destination exists and keeps the existing file', async () => {
    await NativeFileSystem.writeJson({ keep: true }, downloadPath);

    await expect(
      NativeDownloadHandler.download(statusUrl, downloadPath, {})
    ).rejects.toMatchObject({ code: 'FILE_ALREADY_EXISTS' });

    expect(await NativeFileSystem.readJson(downloadPath)).toEqual({
      keep: true,
    });
  });
});
