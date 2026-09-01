import { getNativeModule } from '../native-modules';

export const NotifeeApiModule = {
  get isAvailable(): boolean {
    return !!getNativeModule('NotifeeApiModule');
  },
};
