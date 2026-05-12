import NativeMxOta, {
  type OtaDeployConfig,
  type OtaDownloadConfig,
} from './NativeMxOta';

export const NativeOta = {
  download: (config: OtaDownloadConfig) => NativeMxOta.download(config),
  deploy: (config: OtaDeployConfig) => NativeMxOta.deploy(config),
};
