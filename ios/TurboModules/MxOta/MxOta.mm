#import "MxOta.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxOta

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxOtaSpecJSI>(params);
}

- (void)deploy:(JS::NativeMxOta::OtaDeployConfig &)config
        resolve:(nonnull RCTPromiseResolveBlock)resolve
        reject:(nonnull RCTPromiseRejectBlock)reject {
    OtaDeploymentConfiguration *_config = [[OtaDeploymentConfiguration alloc]
                                    initWithOtaDeploymentID:config.otaDeploymentID()
                                    otaPackage:config.otaPackage()
                                    extractionDir:config.extractionDir()];
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeOtaModule alloc] init] deploy:_config promise:promise];
}

- (void)download:(JS::NativeMxOta::OtaDownloadConfig &)config
        resolve:(nonnull RCTPromiseResolveBlock)resolve
        reject:(nonnull RCTPromiseRejectBlock)reject {
    OtaDownloadConfiguration *_config = [[OtaDownloadConfiguration alloc] initWithUrl:config.url()];
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeOtaModule alloc] init] download:_config promise:promise];
}

@end
