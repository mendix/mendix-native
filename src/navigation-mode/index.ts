import NativeMxNavigation from './NativeMxNavigation';

export const AndroidNavigationBar = {
  height: NativeMxNavigation.getNavigationBarHeight(),
  isActive: NativeMxNavigation.isNavigationBarActive(),
};
