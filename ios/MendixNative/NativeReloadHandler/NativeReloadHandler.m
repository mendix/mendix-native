#import "NativeReloadHandler.h"
#import "ReactNative.h"
#import <React/RCTBridgeModule.h>

@implementation NativeReloadHandler

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(reload) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ReactNative.instance reload];
    });
}

RCT_EXPORT_METHOD(reloadClientWithState) {
    [self sendEventWithName:@"reloadWithState" body:nil];
}

RCT_EXPORT_METHOD(exitApp) {
    exit(0);
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"reloadWithState"];
}

- (NSDictionary *) constantsToExport {
    return @{@"EVENT_RELOAD_WITH_STATE": @"reloadWithState"};
}

+ (BOOL)requiresMainQueueSetup {
	return true;
}

@end
