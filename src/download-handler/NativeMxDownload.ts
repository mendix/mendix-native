import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

type GenericType =
  | string
  | number
  | boolean
  | null
  | undefined
  | { [key: string]: GenericType }
  | GenericType[];

type GenericMap = { [key: string]: GenericType };

type DownloadConfig = {
  connectionTimeout?: CodegenTypes.Int32;
  mimeType?: string;
};

export interface Spec extends TurboModule {
  download(
    url: string,
    downloadPath: string,
    config: GenericMap
  ): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxDownload');

export type { GenericMap, DownloadConfig };
