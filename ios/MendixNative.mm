#import "MendixNative.h"
#import "MendixNative-Swift.h"

@implementation MendixNative

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMendixNativeSpecJSI>(params);
}

- (void)encryptedStorageSetItem:(nonnull NSString *)key value:(nonnull NSString *)value resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [[Promise alloc] initWithResolve:resolve reject:reject];
    [[[EncryptedStorage alloc] init] setItemWithKey:key value:value promise:promise];
}

- (void)encryptedStorageGetItem:(nonnull NSString *)key resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [[Promise alloc] initWithResolve:resolve reject:reject];
    [[[EncryptedStorage alloc] init] getItemWithKey:key promise:promise];
}

- (void)encryptedStorageRemoveItem:(nonnull NSString *)key resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [[Promise alloc] initWithResolve:resolve reject:reject];
    [[[EncryptedStorage alloc] init] removeItemWithKey:key promise:promise];
}

- (void)encryptedStorageClear:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[EncryptedStorage alloc] init] clearWithResolve:resolve reject:reject];
}

- (nonnull NSNumber *)encryptedStorageIsEncrypted {
    return [NSNumber numberWithBool: [EncryptedStorage isEncrypted]];
}

- (void)splashScreenShow {
    [[[MendixSplashScreen alloc] init] show];
}

- (void)splashScreenHide {
    [[[MendixSplashScreen alloc] init] hide];
}

- (void)cookieClearAll:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeCookieModule alloc] init] clearAll:promise];
}

- (void)reloadHandlerReload:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[ReloadHandler alloc] init] reload];
    resolve(nil);
}

- (void)reloadClientWithState {
    [self emitOnReloadWithState];
}

- (void)sendDownloadProgressEvent: (NSDictionary<NSString *,NSNumber *> *) data {
    [self emitOnDownloadProgress:data];
}

- (void)reloadHandlerExitApp:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[ReloadHandler alloc] init] exitApp];
    resolve(nil);
}

- (void)downloadHandlerDownload:(nonnull NSString *)url downloadPath:(nonnull NSString *)downloadPath config:(nonnull NSDictionary *)config resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeDownloadModule alloc] init] download:url downloadPath:downloadPath config:config onProgress:^(NSDictionary<NSString *,NSNumber *> * _Nonnull data) {
        [self emitOnDownloadProgress:data];
    } promise:promise];
}

- (nonnull NSDictionary *)mxConfigurationGetConfig {
    return [[[MxConfiguration alloc] init] constants];
}

- (void)otaDeploy:(nonnull NSDictionary *)config resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeOtaModule alloc] init] deploy:config promise:promise];
}

- (void)otaDownload:(nonnull NSDictionary *)config resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeOtaModule alloc] init] download:config promise:promise];
}

- (void)fsSetEncryptionEnabled:(BOOL)enabled {
    [[[NativeFsModule alloc] init] setEncryptionEnabled:enabled];
}

- (void)fsSave:(nonnull NSDictionary *)blob filePath:(nonnull NSString *)filePath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] save:blob filepath:filePath resolve:resolve reject:reject];
}

- (void)fsRead:(nonnull NSString *)filePath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] read:filePath resolve:resolve reject:reject];
}

- (void)fsMove:(nonnull NSString *)filePath newPath:(nonnull NSString *)newPath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] move:filePath newPath:newPath resolve:resolve reject:reject];
}

- (void)fsRemove:(nonnull NSString *)filePath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] remove:filePath resolve:resolve reject:reject];
}

- (void)fsList:(nonnull NSString *)dirPath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] list:dirPath resolve:resolve reject:reject];
}

- (void)fsReadAsDataURL:(nonnull NSString *)filePath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] readAsDataURL:filePath resolve:resolve reject:reject];
}

- (void)fsFileExists:(nonnull NSString *)filePath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] fileExists:filePath resolve:resolve reject:reject];
}

- (void)fsWriteJson:(nonnull NSDictionary *)data filepath:(nonnull NSString *)filepath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] writeJson:data filepath:filepath resolve:resolve reject:reject];
}


- (void)fsReadJson:(nonnull NSString *)filepath resolve:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] readJson:filepath resolve:resolve reject:reject];
}

- (nonnull NSDictionary *)fsConstants {
    return [[[NativeFsModule alloc] init] constants];
}

- (void)errorHandlerHandle:(nonnull NSString *)message stackTrace:(nonnull NSArray *)stackTrace {
    [[[NativeErrorHandler alloc] init] handleWithMessage:message stackTrace:stackTrace];
}

@end
