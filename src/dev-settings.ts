// Listen for native-to-JS calls to control the shake gesture.
// If the native layer cannot update RCTDevSettings directly,
// enable a listener and use RCTHost.callFunctionOnJSModule to emit the event.
// This pattern can also apply to other methods.
// if (__DEV__ && Platform.OS === 'ios') {
//   DeviceEventEmitter.addListener(
//     'mendixSetShakeToShowDevMenu',
//     (enabled: boolean) => {
//       NativeDevSettings?.setIsShakeToShowDevMenuEnabled?.(enabled);
//     }
//   );
// }
