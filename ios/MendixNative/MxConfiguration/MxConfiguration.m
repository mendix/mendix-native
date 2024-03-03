#import "MxConfiguration.h"
#import "WarningsFilter.h"
#import "OtaJSBundleFileProvider.h"
#import "OtaHelpers.h"
#import "ReactNative.h"

@implementation MxConfiguration

RCT_EXPORT_MODULE();
/**
 *  Increment nativeBinaryVersion to 4 for React native upgrade to version 0.72.7
 */
static NSInteger nativeBinaryVersion = 4;
static NSString *defaultDatabaseName = @"default";
static NSString *defaultFilesDirectoryName = @"files/default";

static NSURL *runtimeUrl;
static NSString *appName;
static NSString *databaseName;
static NSString *filesDirectoryName;
static WarningsFilter warningsFilter;
static NSString *codePushKey;
static BOOL isDeveloperApp;
static NSString *appSessionId;

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

+ (NSURL *) runtimeUrl { return runtimeUrl; }
+ (void) setRuntimeUrl:(NSURL*)value { runtimeUrl = value; }

+ (NSString *) appSessionId { return appSessionId; }
+ (void) setAppSessionId:(NSString*)value { appSessionId = value; }

/**
 * The unique name or identifier that represents the application. This value should always be set to null for non-sample apps
 */
+ (NSString *) appName { return appName; }
+ (void)setAppName:(NSString*)value { appName = value; }

+ (BOOL) isDeveloperApp { return isDeveloperApp; }
+ (void) setIsDeveloperApp:(BOOL)value { isDeveloperApp = value; }

+ (NSString *) databaseName { return databaseName == nil ? defaultDatabaseName : databaseName; }
+ (void)setDatabaseName:(NSString*)value { databaseName = value; }

+ (NSString *) filesDirectoryName { return filesDirectoryName == nil ? defaultFilesDirectoryName : filesDirectoryName; }
+ (void) setFilesDirectoryName:(NSString*)value { filesDirectoryName = value; }

+ (WarningsFilter) warningsFilter { return warningsFilter; }
+ (void) setWarningsFilter:(WarningsFilter)value { warningsFilter = value; }

+ (NSString *) codePushKey { return codePushKey; }
+ (void) setCodePushKey:(NSString *)value { codePushKey = value; }

- (NSDictionary *) constantsToExport
{
    NSURL *runtimeUrl = [MxConfiguration runtimeUrl];
    if (runtimeUrl == nil) {
        @throw [NSException exceptionWithName:@"RUNTIME_URL_MISSING" reason:@"Runtime URL was not set prior to launch." userInfo:nil];
    }
    
    return @{ @"RUNTIME_URL": MxConfiguration.runtimeUrl.absoluteString,
              @"APP_NAME": MxConfiguration.appName ?: [NSNull null],
              @"DATABASE_NAME": MxConfiguration.databaseName,
              @"FILES_DIRECTORY_NAME": MxConfiguration.filesDirectoryName,
              @"WARNINGS_FILTER_LEVEL": WarningsFilter_toString[MxConfiguration.warningsFilter],
              @"CODE_PUSH_KEY": MxConfiguration.codePushKey,
              @"OTA_MANIFEST_PATH": [OtaHelpers getOtaManifestFilepath],
              @"IS_DEVELOPER_APP": [NSNumber numberWithBool: MxConfiguration.isDeveloperApp],
              @"NATIVE_DEPENDENCIES": [OtaHelpers getNativeDependencies] ?: @{},
              @"NATIVE_BINARY_VERSION": [NSNumber numberWithLong:nativeBinaryVersion],
              @"APP_SESSION_ID": MxConfiguration.appSessionId,
    };
}

@end
