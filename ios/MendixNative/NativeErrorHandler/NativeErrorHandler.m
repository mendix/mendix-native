#import "NativeErrorHandler.h"
#import "React/RCTRedBox.h"
#import "ReactNative.h"

// Used by previous versions of the client (<= 9.15)
@implementation NativeErrorHandler

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(handle:(NSString *) message :(NSArray<NSDictionary *> *) stackTrace) {
    RCTRedBox *redbox = [[ReactNative.instance getBridge] redBox];
    if (redbox) {
        [redbox showErrorMessage:message withStack: stackTrace];
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Close App" style:UIAlertActionStyleDefault handler: ^(UIAlertAction *action){
            dispatch_async(dispatch_get_main_queue(), ^{
                exit(EXIT_SUCCESS);
            });
        }]];
        [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
      });
    }
    
    NSLog(@"Received JS exception: %@", message);
}

@end
