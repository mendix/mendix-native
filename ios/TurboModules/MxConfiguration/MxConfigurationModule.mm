#import "MxConfigurationModule.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxConfigurationModule

RCT_EXPORT_MODULE(MxConfiguration)

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxConfigurationSpecJSI>(params);
}

- (nonnull NSDictionary *)getConfig {
    return [[[MxConfiguration alloc] init] constants];
}

@end
