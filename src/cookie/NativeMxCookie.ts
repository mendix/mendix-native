import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  clearAll(): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxCookie');
