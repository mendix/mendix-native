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

export const DevSettings = {
  openDebugger(): void {
    if (!__DEV__) return;
    NativeDevSettings?.openDebugger?.();
  },

  toggleElementInspector(): void {
    if (!__DEV__) return;

    NativeDevSettings?.toggleElementInspector?.();
  },

  reload(reason?: string): void {
    if (!__DEV__) return;
    if (NativeDevSettings?.reloadWithReason) {
      NativeDevSettings.reloadWithReason(reason ?? 'Manual reload from JS');
    } else if (NativeDevSettings?.reload) {
      NativeDevSettings.reload();
    }
  },

  setHotLoadingEnabled(enabled: boolean): void {
    if (__DEV__ && NativeDevSettings?.setHotLoadingEnabled) {
      NativeDevSettings.setHotLoadingEnabled(enabled);
    }
  },

  setProfilingEnabled(enabled: boolean): void {
    if (__DEV__ && NativeDevSettings?.setProfilingEnabled) {
      NativeDevSettings.setProfilingEnabled(enabled);
    }
  },

  setShakeToShowDevMenuEnabled(enabled: boolean): void {
    if (
      __DEV__ &&
      Platform.OS === 'ios' &&
      NativeDevSettings?.setIsShakeToShowDevMenuEnabled
    ) {
      NativeDevSettings.setIsShakeToShowDevMenuEnabled(enabled);
    }
  },

  addMenuItem(title: string, _handler: () => void): void {
    if (__DEV__ && NativeDevSettings?.addMenuItem) {
      NativeDevSettings.addMenuItem(title);
      // Note: Event listener setup would need NativeEventEmitter
    }
  },
};
