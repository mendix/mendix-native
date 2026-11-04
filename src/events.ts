import NativeMxReload, {
  type OnReloadWithState,
} from './reload-handler/NativeMxReload';
import NativeMxOta, { type OnDownloadProgress } from './ota/NativeMxOta';

export const onReloadWithStateEvent: OnReloadWithState =
  NativeMxReload.onReloadWithState;
export const onDownloadProgressEvent: OnDownloadProgress =
  NativeMxOta.onDownloadProgress;
