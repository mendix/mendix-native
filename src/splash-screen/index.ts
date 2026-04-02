import NativeMxSplashScreen from './NativeMxSplashScreen';

/**
 * MxSplashScreen - Native splash screen control
 *
 * Controls the display of the native splash screen during app launch.
 * Typically used to hide the splash screen once the app is ready.
 *
 * @example
 * ```typescript
 * import { MxSplashScreen } from 'mendix-native';
 *
 * // Show splash screen (usually called automatically on launch)
 * MxSplashScreen.show();
 *
 * // Hide splash screen when app is ready
 * MxSplashScreen.hide();
 * ```
 */
export const MxSplashScreen = {
  /**
   * Show the splash screen
   * Displays the native splash screen overlay
   */
  show(): void {
    NativeMxSplashScreen.show();
  },

  /**
   * Hide the splash screen
   * Removes the native splash screen overlay with animation
   */
  hide(): void {
    NativeMxSplashScreen.hide();
  },
};
