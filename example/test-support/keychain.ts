import { TurboModuleRegistry, type TurboModule } from 'react-native';

interface KeychainAttributes {
  accessibility: string;
  expectedAccessibility: string;
  legacyAccessibility: string;
}

interface KeychainTestSupport extends TurboModule {
  seedLegacyItem(key: string, value: string): Promise<void>;
  inspectItem(key: string): Promise<KeychainAttributes | null>;
}

export function getKeychainTestSupport() {
  return TurboModuleRegistry.getEnforcing<KeychainTestSupport>(
    'KeychainTestSupport'
  );
}
