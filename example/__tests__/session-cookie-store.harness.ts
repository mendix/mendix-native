import { beforeEach, describe, expect, test } from 'react-native-harness';
import { NativeCookie, NativeCookieTestHelpers } from 'mendix-native';

// Cookie sizing constants.
// 10 cookies × 7 000-char value → serialised blob ≈ 70–80 KB, above the 64 KB chunk threshold.
const LARGE_COUNT = 10;
const LARGE_VALUE_SIZE = 7_000;
// 3 cookies with tiny values → blob well under 64 KB (single-item path).
const SMALL_COUNT = 3;
const SMALL_VALUE_SIZE = 10;

describe('SessionCookieStore', () => {
  beforeEach(async () => {
    await NativeCookie.clearAll();
  });

  // ---------------------------------------------------------------------------
  // Small-blob (single-item keychain format, ≤ 64 KB)
  // ---------------------------------------------------------------------------

  describe('small-blob round-trip (single-item format)', () => {
    test('persists and restores small cookies', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        SMALL_COUNT,
        SMALL_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();
      await NativeCookieTestHelpers.clearHTTPCookies();

      const names = await NativeCookieTestHelpers.restoreSessionCookies();

      expect(names.length).toBe(SMALL_COUNT);
      for (let i = 0; i < SMALL_COUNT; i++) {
        expect(names).toContain(`testCookie${i}`);
      }
    });

    test('single-item write does not create a chunk commit-marker', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        SMALL_COUNT,
        SMALL_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();

      const chunkCount = await NativeCookieTestHelpers.getKeychainChunkCount();

      expect(chunkCount).toBe(0);
    });

    test('keychain is empty after restore (cleared on read)', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        SMALL_COUNT,
        SMALL_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();
      await NativeCookieTestHelpers.clearHTTPCookies();
      await NativeCookieTestHelpers.restoreSessionCookies();

      // A second restore should find nothing.
      await NativeCookieTestHelpers.clearHTTPCookies();
      const names = await NativeCookieTestHelpers.restoreSessionCookies();

      expect(names.length).toBe(0);
    });
  });

  // ---------------------------------------------------------------------------
  // Large-blob (chunked keychain format, > 64 KB)
  // ---------------------------------------------------------------------------

  describe('large-blob round-trip (chunked format)', () => {
    test('persists and restores large cookies', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        LARGE_COUNT,
        LARGE_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();
      await NativeCookieTestHelpers.clearHTTPCookies();

      const names = await NativeCookieTestHelpers.restoreSessionCookies();

      expect(names.length).toBe(LARGE_COUNT);
      for (let i = 0; i < LARGE_COUNT; i++) {
        expect(names).toContain(`testCookie${i}`);
      }
    });

    test('chunked write creates a commit-marker with count > 1', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        LARGE_COUNT,
        LARGE_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();

      const chunkCount = await NativeCookieTestHelpers.getKeychainChunkCount();

      expect(chunkCount).toBeGreaterThan(1);
    });

    test('commit-marker is removed after restore (chunked keys cleared on read)', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        LARGE_COUNT,
        LARGE_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();
      await NativeCookieTestHelpers.clearHTTPCookies();
      await NativeCookieTestHelpers.restoreSessionCookies();

      const chunkCount = await NativeCookieTestHelpers.getKeychainChunkCount();

      expect(chunkCount).toBe(0);
    });

    test('keychain is empty after restore (no second restore possible)', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        LARGE_COUNT,
        LARGE_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();
      await NativeCookieTestHelpers.clearHTTPCookies();
      await NativeCookieTestHelpers.restoreSessionCookies();

      await NativeCookieTestHelpers.clearHTTPCookies();
      const names = await NativeCookieTestHelpers.restoreSessionCookies();

      expect(names.length).toBe(0);
    });
  });

  // ---------------------------------------------------------------------------
  // Format transitions
  // ---------------------------------------------------------------------------

  describe('format transitions', () => {
    test('overwriting large (chunked) with small (single-item) leaves no chunk marker', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        LARGE_COUNT,
        LARGE_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();

      // Replace with a small set.
      await NativeCookieTestHelpers.clearHTTPCookies();
      await NativeCookieTestHelpers.seedTestCookies(
        SMALL_COUNT,
        SMALL_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();

      const chunkCount = await NativeCookieTestHelpers.getKeychainChunkCount();
      expect(chunkCount).toBe(0);

      // Data is still correct.
      await NativeCookieTestHelpers.clearHTTPCookies();
      const names = await NativeCookieTestHelpers.restoreSessionCookies();
      expect(names.length).toBe(SMALL_COUNT);
    });

    test('overwriting small (single-item) with large (chunked) round-trips correctly', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        SMALL_COUNT,
        SMALL_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();

      // Replace with a large set.
      await NativeCookieTestHelpers.clearHTTPCookies();
      await NativeCookieTestHelpers.seedTestCookies(
        LARGE_COUNT,
        LARGE_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();

      await NativeCookieTestHelpers.clearHTTPCookies();
      const names = await NativeCookieTestHelpers.restoreSessionCookies();
      expect(names.length).toBe(LARGE_COUNT);
    });
  });

  // ---------------------------------------------------------------------------
  // clearAll
  // ---------------------------------------------------------------------------

  describe('clearAll', () => {
    test('removes cookies after a small-blob persist', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        SMALL_COUNT,
        SMALL_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();
      await NativeCookie.clearAll();

      await NativeCookieTestHelpers.clearHTTPCookies();
      const names = await NativeCookieTestHelpers.restoreSessionCookies();
      expect(names.length).toBe(0);
    });

    test('removes cookies and chunk marker after a large-blob persist', async () => {
      await NativeCookieTestHelpers.seedTestCookies(
        LARGE_COUNT,
        LARGE_VALUE_SIZE
      );
      await NativeCookieTestHelpers.persistSessionCookies();
      await NativeCookie.clearAll();

      const chunkCount = await NativeCookieTestHelpers.getKeychainChunkCount();
      expect(chunkCount).toBe(0);

      await NativeCookieTestHelpers.clearHTTPCookies();
      const names = await NativeCookieTestHelpers.restoreSessionCookies();
      expect(names.length).toBe(0);
    });

    test('does not throw when called on an already-empty store', async () => {
      await expect(NativeCookie.clearAll()).resolves.not.toThrow();
      await expect(NativeCookie.clearAll()).resolves.not.toThrow();
    });
  });
});
