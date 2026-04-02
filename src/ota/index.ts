import NativeMxOta from './NativeMxOta';

// Re-export types for backward compatibility
export type {
  OtaDeployConfig,
  OtaDownloadConfig,
  OtaDownloadResponse,
} from './NativeMxOta';

export const NativeOta = {
  download: (config: Record<string, any>) => NativeMxOta.download(config),
  deploy: (config: Record<string, any>) => NativeMxOta.deploy(config),
};
