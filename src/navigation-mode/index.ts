import NativeMxNavigation from './NativeMxNavigation';

// Getters keep this lazy: reading .height/.isActive is what triggers the native call,
// not importing this module.
export const AndroidNavigationBar = {
  get height() {
    return NativeMxNavigation.getNavigationBarHeight();
  },
  get isActive() {
    return NativeMxNavigation.isNavigationBarActive();
  },
};
