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
    config:(JS::NativeMxDownload::DownloadConfig &)config
    resolve:(nonnull RCTPromiseResolveBlock)resolve
    reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    // Note: Progress events are not emitted from this module
    // Use MxOta module for progress events
    NSNumber *connectionTimeout = nil;
    if (config.connectionTimeout().has_value()) {
        connectionTimeout = @(config.connectionTimeout().value());
    }    
    NSString *mimeType = config.mimeType();;
    NativeDownloadModule *downloader = [[NativeDownloadModule alloc] init];
    [downloader download:url downloadPath:downloadPath connectionTimeout:connectionTimeout mimeType:mimeType onProgress:^(NSDictionary* progress) {
//        Uncomment the line below to track progress events.
//        [self emitOnDownloadProgress: progress];
    } promise:promise];
}

@end
