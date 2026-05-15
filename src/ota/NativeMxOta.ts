import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type { CodegenTypes } from 'react-native';

type OtaDownloadConfig = {
  url: string;
};

type OtaDeployConfig = {
  otaDeploymentID: string;
  otaPackage: string;
  extractionDir: string;
};

type OtaDownloadResponse = {
  otaPackage: string;
};

type DownloadProgress = {
  receivedBytes: CodegenTypes.Double;
  totalBytes: CodegenTypes.Double;
};

export interface Spec extends TurboModule {
  download(config: OtaDownloadConfig): Promise<OtaDownloadResponse>;
  deploy(config: OtaDeployConfig): Promise<void>;
  readonly onDownloadProgress: CodegenTypes.EventEmitter<DownloadProgress>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxOta');

export type {
  OtaDownloadConfig,
  OtaDeployConfig,
  OtaDownloadResponse,
  DownloadProgress,
};
