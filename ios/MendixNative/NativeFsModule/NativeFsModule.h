//
//  Copyright (c) Mendix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface NativeFsModule: NSObject<RCTBridgeModule>

+ (void) setEncryptionEnabled:(BOOL)enabled;
+ (BOOL) save:(NSData *_Nonnull)data filepath:(NSString * _Nonnull)filepath error:(NSError *_Nullable*_Nullable)error;
+ (NSData *_Nullable) readData:(NSString *_Nonnull)filePath;
+ (NSDictionary *_Nullable) readJson:(NSString *_Nonnull)filePath error:(NSError *_Nullable *_Nullable)error;
+ (NSArray<NSString *> *_Nullable) list:(NSString *_Nonnull)dirPath;
+ (BOOL) move:(NSString *_Nonnull)filepath newPath:(NSString *_Nonnull)newPath error:(NSError *_Nullable*_Nullable)error;
+ (BOOL) remove:(NSString *_Nonnull)filepath error:(NSError *_Nullable*_Nullable)error;
+ (BOOL) ensureWhiteListedPath:(NSArray<NSString *> *_Nonnull)paths error:(NSError *_Nullable*_Nullable)error;

@end
