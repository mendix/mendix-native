import { describe, expect, test } from 'react-native-harness';
import { DevSettings } from 'mendix-native';

describe('DevSettings', () => {
  test('safe toggle APIs can be invoked repeatedly', () => {
    expect(DevSettings.setHotLoadingEnabled(true)).toBeUndefined();
    expect(DevSettings.setHotLoadingEnabled(false)).toBeUndefined();

    expect(DevSettings.setProfilingEnabled(true)).toBeUndefined();
    expect(DevSettings.setProfilingEnabled(false)).toBeUndefined();

    expect(DevSettings.setShakeToShowDevMenuEnabled(true)).toBeUndefined();
    expect(DevSettings.setShakeToShowDevMenuEnabled(false)).toBeUndefined();
  });

  test('menu items can be registered without throwing', () => {
    expect(
      DevSettings.addMenuItem('Harness menu item', () => {})
    ).toBeUndefined();
  });
});
