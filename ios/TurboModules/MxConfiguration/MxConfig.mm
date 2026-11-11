#import "MxConfig.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxConfig

+ (NSString *)moduleName {
    return @"MxConfig";
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxConfigSpecJSI>(params);
}

- (nonnull facebook::react::ModuleConstants<JS::NativeMxConfig::Constants>)constantsToExport { 
    return [self getConstants];
}

- (nonnull facebook::react::ModuleConstants<JS::NativeMxConfig::Constants>)getConstants {
    MxConfigProxy *config = [MxConfigProxy prepare];
    return facebook::react::typedConstants<JS::NativeMxConfig::Constants>({
        .RUNTIME_URL = config.runtimeUrl,
        .APP_NAME = config.appName ?: [[NSNull alloc] init],
        .FILES_DIRECTORY_NAME = config.filesDirectoryName,
        .DATABASE_NAME = config.databaseName,
        .WARNINGS_FILTER_LEVEL = config.warningsFilter,
        .OTA_MANIFEST_PATH = config.otaManifestPath,
        .NATIVE_DEPENDENCIES = config.nativeDependencies,
        .IS_DEVELOPER_APP = config.isDeveloperApp,
        .NATIVE_BINARY_VERSION = [config.nativeBinaryVersion doubleValue],
        .APP_SESSION_ID = config.appSessionId
    });
}

@end
