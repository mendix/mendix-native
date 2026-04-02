import NativeMxDownload from './NativeMxDownload';

// Re-export DownloadConfig type for backward compatibility
export type { DownloadConfig } from './NativeMxDownload';

export const NativeDownloadHandler = {
  download: (url: string, downloadPath: string, config: Record<string, any>) =>
    NativeMxDownload.download(url, downloadPath, config),
};
