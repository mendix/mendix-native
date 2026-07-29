import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

type DownloadConfig = {
  connectionTimeout?: CodegenTypes.Int32;
  mimeType?: string;
};

type DownloadProgress = {
  receivedBytes: CodegenTypes.Double;
  totalBytes: CodegenTypes.Double;
};

export interface Spec extends TurboModule {
  download(
    url: string,
    downloadPath: string,
    config: DownloadConfig
  ): Promise<void>;

  // Event emitter for download progress
  readonly onDownloadProgress: CodegenTypes.EventEmitter<DownloadProgress>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxDownload');

export type { DownloadConfig, DownloadProgress };
