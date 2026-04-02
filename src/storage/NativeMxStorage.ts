import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  clearDatabases(): Promise<void>;
  closeDatabaseConnections(): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxStorage');
