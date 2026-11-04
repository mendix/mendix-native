#import "MxError.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxError

// Injected by React Native. Lookups here don't need the main thread, unlike DevHelper.getModule.
@synthesize moduleRegistry = _moduleRegistry;

+ (NSString *)moduleName {
    return @"MxError";
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxErrorSpecJSI>(params);
}

- (void)handle:(nonnull NSString *)message
    stackTrace:(nonnull NSArray *)stackTrace {
    [[[NativeErrorHandler alloc] initWithExceptionsManager:[_moduleRegistry moduleForName:"ExceptionsManager"]] handleWithMessage:message stackTrace:stackTrace];
}

@end
