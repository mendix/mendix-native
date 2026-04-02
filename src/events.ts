import NativeMxReload from './reload-handler/NativeMxReload';
import NativeMxOta from './ota/NativeMxOta';

export const onReloadWithStateEvent = NativeMxReload.onReloadWithState;
export const onDownloadProgressEvent = NativeMxOta.onDownloadProgress;
