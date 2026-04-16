import { describe, expect, test } from 'react-native-harness';
import { onDownloadProgressEvent, onReloadWithStateEvent } from 'mendix-native';

describe('Module events', () => {
  test('download progress exposes a removable subscription', () => {
    let callbackCount = 0;

    const subscription = onDownloadProgressEvent(() => {
      callbackCount += 1;
    });

    expect(subscription).toBeDefined();
    expect(typeof subscription.remove).toBe('function');
    expect(callbackCount).toBe(0);

    subscription.remove();
  });

  test('reload state exposes a removable subscription', () => {
    let callbackCount = 0;

    const subscription = onReloadWithStateEvent(() => {
      callbackCount += 1;
    });

    expect(subscription).toBeDefined();
    expect(typeof subscription.remove).toBe('function');
    expect(callbackCount).toBe(0);

    subscription.remove();
  });
});
