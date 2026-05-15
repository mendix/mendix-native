import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

type DownloadConfig = {
  connectionTimeout?: CodegenTypes.Int32;
  mimeType?: string;
};

export interface Spec extends TurboModule {
  download(
    url: string,
    downloadPath: string,
    config: DownloadConfig
  ): Promise<void>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxDownload');

export type { DownloadConfig };
