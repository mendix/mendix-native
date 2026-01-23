import {
  androidPlatform,
  androidEmulator,
} from '@react-native-harness/platform-android';
import {
  applePlatform,
  appleSimulator,
} from '@react-native-harness/platform-apple';

const config = {
  entryPoint: './index.js',
  appRegistryComponentName: 'App',
  bridgeTimeout: 300000,
  bundleStartTimeout: 300000,
  maxAppRestarts: 3,
  resetEnvironmentBetweenTestFiles: true,
  defaultRunner: 'android',
  unstable__skipAlreadyIncludedModules: false,

  runners: [
    androidPlatform({
      name: 'android',
      device: androidEmulator('Pixel_API_35'),
      bundleId: 'mendixnative.example',
    }),
    applePlatform({
      name: 'ios',
      device: appleSimulator('iPhone 17', '26.2'),
      bundleId: 'mendixnative.example',
    }),
  ],
};

export default config;
