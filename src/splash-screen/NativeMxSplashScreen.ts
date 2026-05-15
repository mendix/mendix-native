import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  show(): void;
  hide(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxSplashScreen');
