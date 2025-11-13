import Mx, {
  type OtaDeployConfig,
  type OtaDownloadConfig,
} from './specs/NativeMendixNative';

export const NativeOta = {
  download: (config: OtaDownloadConfig) => Mx.otaDownload(config),
  deploy: (config: OtaDeployConfig) => Mx.otaDeploy(config),
};
