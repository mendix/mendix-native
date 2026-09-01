import { getNativeModule } from '../native-modules';

interface FirebaseMessagingModuleSpec {
  hasPermission(): Promise<number>;
}

export const RNFBMessagingModule = {
  get isAvailable(): boolean {
    return !!getNativeModule<FirebaseMessagingModuleSpec>(
      'RNFBMessagingModule'
    );
  },
  hasPermission(): Promise<number> {
    return getNativeModule<FirebaseMessagingModuleSpec>(
      'RNFBMessagingModule'
    )!.hasPermission();
  },
};
