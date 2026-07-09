import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  clearAll(): Promise<void>;
  // The following methods are only implemented in DEBUG builds.
  // They must not be called in production; doing so will throw a TurboModule lookup error.
  persistTestCookies(count: number, valueSize: number): Promise<void>;
  restoreSessionCookies(): Promise<string[]>;
  getKeychainChunkCount(): Promise<number>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxCookie');
