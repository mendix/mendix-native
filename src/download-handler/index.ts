import NativeMxDownload from './NativeMxDownload';

export const NativeDownloadHandler = {
  download: (url: string, downloadPath: string, config: Record<string, any>) =>
    NativeMxDownload.download(url, downloadPath, config),
};
