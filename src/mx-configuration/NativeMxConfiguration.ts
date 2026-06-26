import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

type Configuration = {
  RUNTIME_URL: string;
  APP_NAME: string | null;
  /**
   * Do not use directly
   * @deprecated
   */
  FILES_DIRECTORY_NAME: string;
  DATABASE_NAME: string;
  WARNINGS_FILTER_LEVEL: string;
  OTA_MANIFEST_PATH: string;
  NATIVE_DEPENDENCIES?: { [key: string]: string };
  IS_DEVELOPER_APP?: boolean;
  /**
   * @deprecated
   */
  CODE_PUSH_KEY?: string;
  NATIVE_BINARY_VERSION?: CodegenTypes.Int32;
  APP_SESSION_ID?: string;
};

export interface Spec extends TurboModule {
  readonly getConstants: () => Configuration;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxConfiguration');

export type { Configuration };
