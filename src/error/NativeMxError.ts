import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { StackFrame } from 'stacktrace-parser';

export interface Spec extends TurboModule {
  handle(message: string, stackTrace: StackFrame[]): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxError');
