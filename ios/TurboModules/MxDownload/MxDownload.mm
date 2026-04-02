#import "MxDownload.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxDownload

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxDownloadSpecJSI>(params);
}

- (void)download:(nonnull NSString *)url
    downloadPath:(nonnull NSString *)downloadPath
          config:(nonnull NSDictionary *)config
         resolve:(nonnull RCTPromiseResolveBlock)resolve
          reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    // Note: Progress events are not emitted from this module
    // Use MxOta module for progress events
    [[[NativeDownloadModule alloc] init] download:url downloadPath:downloadPath config:config onProgress:nil promise:promise];
}

@end
