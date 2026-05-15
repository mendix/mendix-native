#import "MxError.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxError

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxErrorSpecJSI>(params);
}

- (void)handle:(nonnull NSString *)message
    stackTrace:(nonnull NSArray *)stackTrace {
    [[[NativeErrorHandler alloc] init] handleWithMessage:message stackTrace:stackTrace];
}

@end
