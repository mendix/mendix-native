import { TurboModuleRegistry, type TurboModule } from 'react-native';

/**
 * MxSplashScreen TurboModule
 *
 * Controls the native splash screen display during app launch.
 */
export interface Spec extends TurboModule {
  /**
   * Show the splash screen
   * Displays the native splash screen overlay
   */
  show(): void;

  /**
   * Hide the splash screen
   * Removes the native splash screen overlay with animation
   */
  hide(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxSplashScreen');
