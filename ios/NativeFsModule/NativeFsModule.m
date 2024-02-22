#import "NativeFsModule.h"
#import "ReactNative.h"
#import "SSZipArchive.h"
#import <Foundation/Foundation.h>
#import <React/RCTBlobManager.h>
#import <React/RCTEventEmitter.h>

BOOL _enableEncryption;

@implementation NativeFsModule

RCT_EXPORT_MODULE()

NSString *ERROR_SAVE_FAILED = @"ERROR_SAVE_FAILED";
NSString *ERROR_READ_FAILED = @"ERROR_READ_FAILED";
NSString *ERROR_MOVE_FAILED = @"ERROR_MOVE_FAILED";
NSString *ERROR_DELETE_FAILED = @"ERROR_DELETE_FAILED";
NSString *ERROR_SERIALIZATION_FAILED = @"ERROR_SERIALIZATION_FAILED";
NSString *INVALID_PATH = @"INVALID_PATH";

NSErrorDomain const NativeFsErrorDomain =
    @"com.mendix.mendixnative.nativefsmodule";

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

+ (void)setEncryptionEnabled:(BOOL)e {
    _enableEncryption = e;
}

+ (NSString *)formatError:(NSString *)message {
    return [[[NativeFsModule description] stringByAppendingString:@": "]
        stringByAppendingString:message];
}

+ (NSData *)readBlobRefAsData:(NSDictionary<NSString *, id> *)blob {
    RCTBlobManager *blobManager =
        [[ReactNative.instance getBridge] moduleForClass:RCTBlobManager.class];
    return [blobManager resolve:blob];
}

+ (NSDictionary *)readDataAsBlobRef:(NSData *)data {
    RCTBlobManager *blobManager =
        [[ReactNative.instance getBridge] moduleForClass:RCTBlobManager.class];

    return @{
        @"blobId" : [blobManager store:data],
        @"offset" : @0,
        @"length" : @(data.length)
    };
}

+ (NSData *)readData:(NSString *)filePath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }

    NSError *error;
    NSData *data =
        [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]
                              options:NSDataReadingMappedAlways
                                error:&error];
    if (error) {
        return nil;
    }

    return data;
}

+ (NSDictionary *)readJson:(NSString *)filePath
                     error:(NSError *_Nullable *)error {
    NSData *data = [NativeFsModule readData:filePath];
    if (data == nil) {
        return nil;
    }
    
    NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingMutableContainers
                                                          error:error];
    if (error && *error) {
        return nil;
    }

    return res;
}

+ (BOOL)save:(NSData *)data
    filepath:(NSString *)filepath
       error:(NSError *_Nullable *)error {
    NSURL *directoryUrl =
        [NSURL fileURLWithPath:[filepath stringByDeletingLastPathComponent]];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryUrl
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:error];
    if (error && *error) {
        return false;
    }
    
    NSDataWritingOptions options = NSDataWritingAtomic;
    if (_enableEncryption) {
        options = NSDataWritingAtomic | NSDataWritingFileProtectionComplete;
    }

    [data writeToURL:[NSURL fileURLWithPath:filepath]
             options:options
               error:error];
    if (error && *error) {
        return false;
    }

    return true;
}

+ (BOOL)move:(NSString *)filepath
     newPath:(NSString *)newPath
       error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filepath]) {
        *error = [NSError
            errorWithDomain:NativeFsErrorDomain
                       code:-1
                   userInfo:@{
                       NSLocalizedDescriptionKey : @"File does not exist"
                   }];
        return false;
    }

    NSURL *directoryUrl =
        [NSURL fileURLWithPath:[newPath stringByDeletingLastPathComponent]];

    [[NSFileManager defaultManager] createDirectoryAtURL:directoryUrl
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:error];
    if (error && *error) {
        return false;
    }

    [fileManager moveItemAtPath:filepath toPath:newPath error:error];
    if (error && *error) {
        return false;
    }

    return true;
}

+ (BOOL)remove:(NSString *)filepath error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filepath]) {
        return false;
    }

    [fileManager removeItemAtPath:filepath error:error];
    if (error && *error) {
        return false;
    }
    return true;
}

+ (BOOL)ensureWhiteListedPath:(NSArray<NSString *> *)paths
                        error:(NSError **)error {
    for (id path in paths) {
        if (!([path hasPrefix:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]] ||
            [path hasPrefix:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]] || [path hasPrefix:[NSTemporaryDirectory() stringByStandardizingPath]])) {
            *error = [NSError
                errorWithDomain:NativeFsErrorDomain
                           code:999
                       userInfo:@{
                           NSLocalizedDescriptionKey : [NSString
                               stringWithFormat:@"The path %@ does not point "
                                                @"to the documents directory",
                                                path]
                       }];
            return false;
        }
    }
    return true;
}

+ (NSArray<NSString *> *)list:(NSString *)dirPath {
    NSArray<NSString *> *listedFiles =
        [[[NSFileManager defaultManager] enumeratorAtPath:dirPath] allObjects];
    return listedFiles == nil ? @[] : listedFiles;
}

RCT_EXPORT_METHOD(setEncryptionEnabled
                  : (BOOL) enabled
                  ) {
    [NativeFsModule setEncryptionEnabled:enabled];
}

RCT_EXPORT_METHOD(save
                  : (NSDictionary<NSString *, id> *)blob filepath
                  : (NSString *)filepath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:filepath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }

    NSData *data = [NativeFsModule readBlobRefAsData:blob];
    [NativeFsModule save:data filepath:filepath error:&error];
    if (error) {
        return reject(ERROR_SAVE_FAILED,
                      [NativeFsModule formatError:@"Save failed"], error);
    }

    resolve(nil);
}

RCT_EXPORT_METHOD(read
                  : (NSString *)filepath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSData *data;
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:filepath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }

    data = [NativeFsModule readData:filepath];
    if (data == nil) {
        return resolve(nil);
    }
    
    NSDictionary<NSString *, id> *blob =
        [NativeFsModule readDataAsBlobRef:data];

    resolve(blob);
}

RCT_EXPORT_METHOD(move
                  : (NSString *)filepath
                  : (NSString *)newPath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObjects:filepath, newPath, nil]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }

    [NativeFsModule move:filepath newPath:newPath error:&error];
    if (error) {
        return reject(ERROR_MOVE_FAILED,
                      [NativeFsModule formatError:@"Failed to move file"],
                      error);
    }

    resolve(nil);
}

RCT_EXPORT_METHOD(remove
                  : (NSString *)filepath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:filepath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }

    [NativeFsModule remove:filepath error:&error];
    if (error) {
        return reject(ERROR_DELETE_FAILED,
                      [NativeFsModule formatError:@"Failed to delete file"],
                      error);
    }

    resolve(nil);
}

RCT_EXPORT_METHOD(list
                  : (NSString *)dirPath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:dirPath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }
    resolve([NativeFsModule list:dirPath]);
}

RCT_EXPORT_METHOD(readAsDataURL
                  : (NSString *)filePath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:filePath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }

    NSData *data;
    data = [NativeFsModule readData:filePath];
    if (!data) {
        return resolve(nil);
    }

    NSDictionary<NSString *, id> *blob =
        [NativeFsModule readDataAsBlobRef:data];
    NSString *type =
        blob[@"type"] != nil ? blob[@"type"] : @"application/octet-stream";
    NSString *text =
        [NSString stringWithFormat:@"data:%@;base64,%@", type,
                                   [data base64EncodedStringWithOptions:0]];
    resolve(text);
}

RCT_EXPORT_METHOD(fileExists
                  : (NSString *)filepath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:filepath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }

    bool exists = [[NSFileManager defaultManager] fileExistsAtPath:filepath];
    return resolve([NSNumber numberWithBool:exists]);
}

RCT_EXPORT_METHOD(readJson
                  : (NSString *)filepath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:filepath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH,
                      [NativeFsModule formatError:@"Path not accessible"],
                      error);
    }

    NSDictionary *data = [NativeFsModule readJson:filepath
                                            error:&error];
    if (error) {
        reject(ERROR_SERIALIZATION_FAILED, [NativeFsModule formatError:@"Failed to deserialize JSON"], error);
        return;
    }

    resolve(data);
}

RCT_EXPORT_METHOD(writeJson
                  : (NSDictionary<NSString *, id> *)data filepath
                  : (NSString *)filepath resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSError *error;
    [NativeFsModule ensureWhiteListedPath:[NSArray arrayWithObject:filepath]
                                    error:&error];
    if (error) {
        return reject(INVALID_PATH, @"Path not accessible", error);
    }

    NSData *res =
        [NSJSONSerialization dataWithJSONObject:data
                                        options:NSJSONWritingPrettyPrinted
                                          error:&error];
    if (error) {
        reject(ERROR_SERIALIZATION_FAILED,
               [NativeFsModule formatError:@"Failed to serialize JSON"], error);
        return;
    }

    [NativeFsModule save:res filepath:filepath error:&error];
    if (error) {
        return reject(ERROR_SAVE_FAILED,
                      [NativeFsModule formatError:@"Failed to write JSON"],
                      error);
    }

    resolve(nil);
}

- (NSDictionary *)constantsToExport {
    return @{
        @"DocumentDirectoryPath" : [NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES) firstObject],
        @"SUPPORTS_DIRECTORY_MOVE" : @YES,
        @"SUPPORTS_ENCRYPTION" : @YES
    };
}

@end
