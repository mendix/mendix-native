import Mx, { type DownloadConfig } from './specs/NativeMendixNative';

export const NativeDownloadHandler = {
  download: (url: string, downloadPath: string, config: DownloadConfig) =>
    Mx.downloadHandlerDownload(url, downloadPath, config),
};
