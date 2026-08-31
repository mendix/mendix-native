import type { TurboModule, CodegenTypes } from 'react-native';

const TurboModuleRegistry =
  require('react-native/Libraries/TurboModule/TurboModuleRegistry') as {
    getEnforcing: <T extends object>(name: string) => T;
  };

export interface Spec extends TurboModule {
  isNavigationBarActive(): boolean;
  getNavigationBarHeight(): CodegenTypes.Double;
}

let cachedModule: Spec | undefined;
const getModule = (): Spec => {
  if (!cachedModule) {
    cachedModule = TurboModuleRegistry.getEnforcing<Spec>('MxNavigation');
  }
  return cachedModule;
};

// Resolves the native module lazily (on first property access) instead of at import time,
// so requiring this file on web, where TurboModuleRegistry is stubbed out, never crashes.
const NativeMxNavigation = new Proxy({} as Spec, {
  get(_target, prop) {
    return getModule()[prop as keyof Spec];
  },
});

export default NativeMxNavigation;
