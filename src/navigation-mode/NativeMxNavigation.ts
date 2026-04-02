import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

export interface Spec extends TurboModule {
  isNavigationBarActive(): boolean;
  getNavigationBarHeight(): CodegenTypes.Double;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxNavigation');
