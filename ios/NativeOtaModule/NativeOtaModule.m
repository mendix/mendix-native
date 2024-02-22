#import "NativeOtaModule.h"
#import "MxConfiguration.h"
#import "NativeDownloadHandler.h"
#import "OtaConstants.h"
#import "OtaHelpers.h"
#import "SSZipArchive.h"
#import <Foundation/Foundation.h>

@implementation NativeOtaModule

RCT_EXPORT_MODULE()

+ (NSString *)resolveAppVersion {
    return [OtaHelpers resolveAppVersion];
}

+ (void)initialize {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *otaDir = [OtaHelpers getOtaDir];
    [[NSFileManager.defaultManager URLsForDirectory:NSLibraryDirectory
                                          inDomains:NSAllDomainsMask]
            .firstObject URLByAppendingPathComponent:@"Ota"];
    [fileManager createDirectoryAtPath:otaDir
           withIntermediateDirectories:true
                            attributes:nil
                                 error:nil];
}

/**
 * Accepts a structure of:
 * {
 *    url: string, // url to download from
 * }
 *
 * Returns a structure of:
 * {
 *    otaPackage: string // zip file name
 * }
 */
RCT_EXPORT_METHOD(download
                  : (NSDictionary *)config resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    NSString *otaDir = [OtaHelpers getOtaDir];
    if (![NSFileManager.defaultManager fileExistsAtPath:otaDir]) {
        [NSFileManager.defaultManager createDirectoryAtPath:otaDir
                                withIntermediateDirectories:true
                                                 attributes:NULL
                                                      error:&error];
        if (error) {
            reject(OTA_DOWNLOAD_FAILED, @"Failed creating ota directories",
                   nil);
            return;
        }
    }

    NSString *url = config[DOWNLOAD_CONFIG_URL_KEY];
    if (!url) {
        reject(INVALID_DOWNLOAD_CONFIG, @"Key url is invalid.", nil);
        return;
    }

    bool isRuntimeUrl =
        [[url substringToIndex:MxConfiguration.runtimeUrl.absoluteString.length]
            isEqualToString:MxConfiguration.runtimeUrl.absoluteString];
    if (!isRuntimeUrl) {
        reject(INVALID_RUNTIME_URL, @"Invalid OTA URL.", nil);
        return;
    }

    NSString *zipFilename = [self generateZipFilename];
    NativeDownloadHandler *downloadHandler =
        [[NativeDownloadHandler alloc] init:@{}
            doneCallback:^(void) {
              resolve(@{@"otaPackage" : zipFilename});
            }
            progressCallback:nil
            failCallback:^(NSError *err) {
              reject(OTA_DOWNLOAD_FAILED, @"OTA download failed.", err);
            }];
    [downloadHandler
            download:url
        downloadPath:[OtaHelpers
                         resolveAbsolutePathRelativeToOtaDir:
                             [@"/" stringByAppendingString:zipFilename]]];
}

/**
 * Accepts a structure:
 * {
 *    otaDeploymentID: string, // current ota deployment id
 *    otaPackage: string, // the zip filename to unzip
 *    extractionDir: string, // the relative path to extract the bundle to
 * }
 *
 * Generates a manifest.json:
 * {
 *   otaDeploymentID: string, // current ota deployment id
 *   relativeBundlePath: string, // relative path to the index.*.bundle
 *   appVersion: string //  version number + code at installation time
 * }
 */
RCT_EXPORT_METHOD(deploy
                  : (NSDictionary *)config resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSString *otaDeploymentID = config[MANIFEST_OTA_DEPLOYMENT_ID_KEY];
    if (!otaDeploymentID) {
        reject(INVALID_DOWNLOAD_CONFIG, @"Key otaDeploymentID is invalid.",
               nil);
        return;
    }

    NSString *zipFile = config[DEPLOY_CONFIG_OTA_PACKAGE_KEY];
    if (!zipFile) {
        reject(INVALID_DOWNLOAD_CONFIG, @"Key otaPackage is invalid.", nil);
        return;
    }

    NSString *extractionDir = config[DEPLOY_CONFIG_EXTRACTION_DIR];
    if (!extractionDir) {
        reject(INVALID_DOWNLOAD_CONFIG, @"Key extractionDir is invalid.", nil);
        return;
    }

    NSString *zipPath = [OtaHelpers resolveAbsolutePathRelativeToOtaDir:
                                        [@"/" stringByAppendingString:zipFile]];
    NSString *unzipDir =
        [OtaHelpers resolveAbsolutePathRelativeToOtaDir:
                        [@"/" stringByAppendingString:extractionDir]];

    NSDictionary *oldManifest = [OtaHelpers readManifestAsDictionary];

    bool fileExists = [NSFileManager.defaultManager fileExistsAtPath:zipPath];
    if (!fileExists) {
        NSString *errorMessage = @"[OTA] OTA package does not exist.";
        NSLog(@"%@", errorMessage);
        reject(OTA_ZIP_FILE_MISSING, errorMessage, nil);
        return;
    }

    bool extractionDirExists =
        [NSFileManager.defaultManager fileExistsAtPath:unzipDir];
    if (extractionDirExists) {
        NSLog(@"[OTA] Extraction directory exists. Removing it.");
        [self removeOldBundle:unzipDir];
    }

    NSError *error;
    BOOL uzipped = [SSZipArchive unzipFileAtPath:zipPath
                                   toDestination:unzipDir
                                       overwrite:false
                                        password:nil
                                           error:&error];
    if (!uzipped) {
        NSLog(@"[OTA] Unzipping OTA failed");
        [self removeZipFile:unzipDir];
        reject(OTA_DEPLOYMENT_FAILED, @"OTA deployment failed.", error);
        return;
    }

    NSData *manifest =
        [NSJSONSerialization dataWithJSONObject:@{
            MANIFEST_OTA_DEPLOYMENT_ID_KEY : otaDeploymentID,
            MANIFEST_RELATIVE_BUNDLE_PATH_KEY : [extractionDir
                stringByAppendingString:
                    [@"/" stringByAppendingString:@"index.ios.bundle"]],
            MANIFEST_APP_VERSION_KEY : [NativeOtaModule resolveAppVersion]
        }
                                        options:NSJSONWritingPrettyPrinted
                                          error:&error];
    if (manifest == nil) {
        NSLog(@"[OTA] Manifest serialization failed");
        [NSFileManager.defaultManager removeItemAtPath:unzipDir error:nil];
        reject(OTA_DEPLOYMENT_FAILED, @"Serializing new OTA manifest failed.",
               error);
        return;
    }

    BOOL manifestWritten = [manifest
        writeToFile:[OtaHelpers
                        resolveAbsolutePathRelativeToOtaDir:
                            [@"/" stringByAppendingString:MANIFEST_FILE_NAME]]
            options:NSDataWritingAtomic
              error:&error];

    if (!manifestWritten) {
        NSLog(@"[OTA] Writing manifest failed");
        [NSFileManager.defaultManager removeItemAtPath:unzipDir error:nil];
        reject(OTA_DEPLOYMENT_FAILED, @"Writing OTA manifest failed.", error);
        return;
    }

#pragma mark - Old bundle cleanup

    BOOL shouldRemoveOldBundle =
        oldManifest != nil &&
        ![otaDeploymentID isEqual:oldManifest[MANIFEST_OTA_DEPLOYMENT_ID_KEY]];
    if (shouldRemoveOldBundle) {
        [self
            removeOldBundle:
                [OtaHelpers
                    resolveAbsolutePathRelativeToOtaDir:
                        [@"/"
                            stringByAppendingString:
                                [oldManifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY]
                                    stringByDeletingLastPathComponent]]]];
    }

    [self removeZipFile:zipPath];

    NSLog(@"[OTA] OTA deployed.");
    resolve(nil);
}

#pragma mark - Private

- (NSString *)generateZipFilename {
    return [[[NSUUID UUID] UUIDString] stringByAppendingString:@".zip"];
}

- (BOOL)removeZipFile:(NSString *)zipPath {
    NSError *error;
    BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:zipPath
                                                              error:&error];
    if (!removed) {
        NSLog(@"[OTA] Error: %@ %@", error, [error userInfo]);
    }
    return removed;
}

- (BOOL)removeOldBundle:(NSString *)bundleDir {
    NSError *error;
    BOOL oldBundleDirectoryRemoved =
        [[NSFileManager defaultManager] removeItemAtPath:bundleDir
                                                   error:&error];
    if (!oldBundleDirectoryRemoved) {
        NSLog(@"[OTA] Error: %@ %@", error, [error userInfo]);
    }
    return oldBundleDirectoryRemoved;
}

@end
