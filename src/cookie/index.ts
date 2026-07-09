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
  /** Writes N synthetic session cookies directly to the keychain (bypasses HTTPCookieStorage). Resolves when the write completes. */
  persistTestCookies: NativeMxCookie.persistTestCookies,
  /** Reads cookies directly from the keychain, clears the entry, and returns their names (bypasses HTTPCookieStorage). */
  restoreSessionCookies: NativeMxCookie.restoreSessionCookies,
  /** Returns the _chunkcount commit-marker value (> 1 = chunked write; 0 = single-item or empty). */
  getKeychainChunkCount: NativeMxCookie.getKeychainChunkCount,
};
