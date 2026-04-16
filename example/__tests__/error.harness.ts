import { describe, expect, test } from 'react-native-harness';
import { NativeErrorHandler } from 'mendix-native';

describe('NativeErrorHandler', () => {
  test('accepts normalized stack frame payloads synchronously', () => {
    const stackTrace = [
      {
        column: 12,
        file: 'example/__tests__/error.harness.ts',
        lineNumber: 8,
        methodName: 'accepts normalized stack frame payloads synchronously',
      },
    ] as any;

    expect(() => {
      const result = NativeErrorHandler.handle(
        'Harness error contract check',
        stackTrace
      );

      expect(result).toBeUndefined();
    }).not.toThrow();
  });
});
