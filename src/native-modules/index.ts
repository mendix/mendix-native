const TurboModuleRegistry =
  require('react-native/Libraries/TurboModule/TurboModuleRegistry') as {
    get: <T extends object = Record<string, unknown>>(name: string) => T | null;
  };

export const getNativeModule = <T extends object = Record<string, unknown>>(
  name: string
): T | null => TurboModuleRegistry.get<T>(name);
