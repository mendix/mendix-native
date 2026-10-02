import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

export interface Spec extends TurboModule {
  reload(): Promise<void>;
  exitApp(): Promise<void>;
  readonly onReloadWithState: CodegenTypes.EventEmitter<void>;
}

// Codegen requires EventEmitter inline in Spec, so derive the alias from it.
export type OnReloadWithState = Spec['onReloadWithState'];

export default TurboModuleRegistry.getEnforcing<Spec>('MxReload');
