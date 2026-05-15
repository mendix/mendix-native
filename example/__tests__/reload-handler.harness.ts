import { describe, expect, test } from 'react-native-harness';
import { NativeReloadHandler, onReloadWithStateEvent } from 'mendix-native';

describe('NativeReloadHandler', () => {
  test('exposes async control methods and a removable state listener', () => {
    const subscription = onReloadWithStateEvent(() => {});

    expect(typeof NativeReloadHandler.reload).toBe('function');
    expect(typeof NativeReloadHandler.exitApp).toBe('function');
    expect(typeof subscription.remove).toBe('function');

    subscription.remove();
  });
});
