import NativeMxCookie from './NativeMxCookie';

export const NativeCookie = {
  clearAll: NativeMxCookie.clearAll,
};

/**
 * Test-only helpers — available in DEBUG builds only.
 * Never call these in production code; the native implementations are stripped
 * from release binaries and calls will throw a TurboModule lookup error.
 */
export const NativeCookieTestHelpers = {
  /** Seeds session cookies into HTTPCookieStorage. */
  seedTestCookies: NativeMxCookie.seedTestCookies,
  /** Persists current session cookies to the keychain. Resolves when the write completes. */
  persistSessionCookies: NativeMxCookie.persistSessionCookies,
  /** Clears all cookies from HTTPCookieStorage without touching the keychain (simulates an app restart). */
  clearHTTPCookies: NativeMxCookie.clearHTTPCookies,
  /** Restores cookies from the keychain into HTTPCookieStorage and returns their names. */
  restoreSessionCookies: NativeMxCookie.restoreSessionCookies,
  /** Returns the _chunkcount commit-marker value (> 1 = chunked write; 0 = single-item or empty). */
  getKeychainChunkCount: NativeMxCookie.getKeychainChunkCount,
};
