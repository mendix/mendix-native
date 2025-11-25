import NativeMendixNative from './specs/NativeMendixNative';

/**
 * Navigation Mode Module
 *
 * Provides information about Android navigation bar state.
 * These methods are synchronous and Android-only.
 * On iOS, they always return false/0.
 */

/**
 * Checks if the navigation bar is active on Android.
 * Returns true for three-button and two-button navigation modes.
 * Returns false for gesture navigation mode.
 * On iOS, always returns false.
 *
 * @returns {boolean} true if navigation bar is active, false otherwise
 */
export function isNavigationBarActive(): boolean {
  return NativeMendixNative.navigationModeIsNavigationBarActive();
}

/**
 * Gets the navigation bar height in density-independent pixels (dp).
 * On Android, returns the actual navigation bar height.
 * On iOS, always returns 0.
 *
 * @returns {number} Navigation bar height in dp
 */
export function getNavigationBarHeight(): number {
  return NativeMendixNative.navigationModeGetNavigationBarHeight();
}
