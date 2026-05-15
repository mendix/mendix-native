#import "MxFileSystem.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxFileSystem

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxFileSystemSpecJSI>(params);
}

- (nonnull NSDictionary *)constants {
    return [[[NativeFsModule alloc] init] constants];
}

- (void)save:(nonnull NSDictionary *)blob
    filePath:(nonnull NSString *)filePath
     resolve:(nonnull RCTPromiseResolveBlock)resolve
      reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] save:blob filepath:filePath resolve:resolve reject:reject];
}

- (void)read:(nonnull NSString *)filePath
     resolve:(nonnull RCTPromiseResolveBlock)resolve
      reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] read:filePath resolve:resolve reject:reject];
}

- (void)move:(nonnull NSString *)filePath
     newPath:(nonnull NSString *)newPath
     resolve:(nonnull RCTPromiseResolveBlock)resolve
      reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] move:filePath newPath:newPath resolve:resolve reject:reject];
}

- (void)remove:(nonnull NSString *)filePath
       resolve:(nonnull RCTPromiseResolveBlock)resolve
        reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] remove:filePath resolve:resolve reject:reject];
}

- (void)list:(nonnull NSString *)dirPath
     resolve:(nonnull RCTPromiseResolveBlock)resolve
      reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] list:dirPath resolve:resolve reject:reject];
}

- (void)readAsDataURL:(nonnull NSString *)filePath
              resolve:(nonnull RCTPromiseResolveBlock)resolve
               reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] readAsDataURL:filePath resolve:resolve reject:reject];
}

- (void)readAsText:(nonnull NSString *)filePath
           resolve:(nonnull RCTPromiseResolveBlock)resolve
            reject:(nonnull RCTPromiseRejectBlock)reject {
    reject(@"NOT_SUPPORTED", @"Read as text is not supported on iOS", nil);
}

- (void)fileExists:(nonnull NSString *)filePath
           resolve:(nonnull RCTPromiseResolveBlock)resolve
            reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] fileExists:filePath resolve:resolve reject:reject];
}

- (void)writeJson:(nonnull NSDictionary *)data
         filepath:(nonnull NSString *)filepath
          resolve:(nonnull RCTPromiseResolveBlock)resolve
           reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] writeJson:data filepath:filepath resolve:resolve reject:reject];
}

- (void)readJson:(nonnull NSString *)filepath
         resolve:(nonnull RCTPromiseResolveBlock)resolve
          reject:(nonnull RCTPromiseRejectBlock)reject {
    [[[NativeFsModule alloc] init] readJson:filepath resolve:resolve reject:reject];
}

- (void)setEncryptionEnabled:(BOOL)enabled {
    [[[NativeFsModule alloc] init] setEncryptionEnabled:enabled];
}

@end
