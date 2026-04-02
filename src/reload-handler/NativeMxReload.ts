import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

export interface Spec extends TurboModule {
  reload(): Promise<void>;
  exitApp(): Promise<void>;
  readonly onReloadWithState: CodegenTypes.EventEmitter<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxReload');
