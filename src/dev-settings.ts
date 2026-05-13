import { DeviceEventEmitter, NativeModules, Platform } from 'react-native';

const NativeDevSettings = NativeModules.DevSettings;

// Listen for native-to-JS calls to control shake gesture.
// In RN 0.84+ bridgeless mode, native cannot directly set this on RCTDevSettings
// because the TurboModule instance isn't accessible via moduleForName. Instead,
// native uses RCTHost.callFunctionOnJSModule to emit this event.
if (__DEV__ && Platform.OS === 'ios') {
  DeviceEventEmitter.addListener(
    'mendixSetShakeToShowDevMenu',
    (enabled: boolean) => {
      NativeDevSettings?.setIsShakeToShowDevMenuEnabled?.(enabled);
    }
  );
}

/**
 * Controls debugging and development settings using React Native's built-in APIs.
 *
 * **Modern Architecture:** Calls React Native's DevSettings TurboModule directly
 * without using the legacy RCTBridge, providing better performance and compatibility
 * with React Native's New Architecture.
 *
 * In RN 0.83+, the deprecated `setIsDebuggingRemotely` API was removed and replaced
 * with modern on-device debugging tools accessed through these methods.
 */
export const DevSettings = {
  /**
   * Opens the debugger (Chrome DevTools or Hermes debugger).
   * In RN 0.83+, this replaces the deprecated `setIsDebuggingRemotely` API.
   *
   * Calls React Native's DevSettings TurboModule directly.
   */
  openDebugger(): void {
    if (!__DEV__) return;

    // Call React Native's DevSettings TurboModule directly (no bridge)
    NativeDevSettings?.openDebugger?.();
  },

  /**
   * Toggles the element inspector overlay.
   *
   * Calls React Native's DevSettings TurboModule directly.
   */
  toggleElementInspector(): void {
    if (!__DEV__) return;

    // Call React Native's DevSettings TurboModule directly (no bridge)
    NativeDevSettings?.toggleElementInspector?.();
  },

  /**
   * Reloads the JavaScript bundle.
   *
   * Calls React Native's DevSettings TurboModule directly.
   *
   * @param reason Optional reason for the reload
   */
  reload(reason?: string): void {
    if (!__DEV__) return;

    // Call React Native's DevSettings TurboModule directly (no bridge)
    if (NativeDevSettings?.reloadWithReason) {
      NativeDevSettings.reloadWithReason(reason ?? 'Manual reload from JS');
    } else if (NativeDevSettings?.reload) {
      NativeDevSettings.reload();
    }
  },

  /**
   * Controls hot reloading (Fast Refresh).
   */
  setHotLoadingEnabled(enabled: boolean): void {
    if (__DEV__ && NativeDevSettings?.setHotLoadingEnabled) {
      NativeDevSettings.setHotLoadingEnabled(enabled);
    }
  },

  /**
   * Controls React profiling.
   */
  setProfilingEnabled(enabled: boolean): void {
    if (__DEV__ && NativeDevSettings?.setProfilingEnabled) {
      NativeDevSettings.setProfilingEnabled(enabled);
    }
  },

  /**
   * Controls shake gesture for dev menu (iOS only).
   */
  setShakeToShowDevMenuEnabled(enabled: boolean): void {
    if (
      __DEV__ &&
      Platform.OS === 'ios' &&
      NativeDevSettings?.setIsShakeToShowDevMenuEnabled
    ) {
      NativeDevSettings.setIsShakeToShowDevMenuEnabled(enabled);
    }
  },

  /**
   * Adds a custom menu item to the dev menu.
   */
  addMenuItem(title: string, _handler: () => void): void {
    if (__DEV__ && NativeDevSettings?.addMenuItem) {
      NativeDevSettings.addMenuItem(title);
      // Note: Event listener setup would need NativeEventEmitter
      // See DevSettings.js in react-native for full implementation
    }
  },
};
