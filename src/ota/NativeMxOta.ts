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
  download(config: GenericMap): Promise<OtaDownloadResponse>;
  deploy(config: GenericMap): Promise<void>;
  readonly onDownloadProgress: CodegenTypes.EventEmitter<DownloadProgress>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('MxOta');

export type {
  GenericMap,
  OtaDownloadConfig,
  OtaDeployConfig,
  OtaDownloadResponse,
  DownloadProgress,
};
