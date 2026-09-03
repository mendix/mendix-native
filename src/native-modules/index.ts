import { TurboModuleRegistry } from 'react-native';

export const getNativeModule = <T extends object = Record<string, unknown>>(
  name: string
): T | null => TurboModuleRegistry.get<T>(name) ?? null;
