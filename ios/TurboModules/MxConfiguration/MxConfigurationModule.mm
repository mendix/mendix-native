#import "MxConfigurationModule.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxConfigurationModule

RCT_EXPORT_MODULE(MxConfiguration)

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxConfigurationSpecJSI>(params);
}

- (nonnull facebook::react::ModuleConstants<JS::NativeMxConfiguration::Constants>)constantsToExport { 
    return [self getConstants];
}

- (nonnull facebook::react::ModuleConstants<JS::NativeMxConfiguration::Constants>)getConstants {
    MxConfigProxy *config = [MxConfigProxy prepare];
    return facebook::react::typedConstants<JS::NativeMxConfiguration::Constants>({
        .RUNTIME_URL = config.runtimeUrl,
        .APP_NAME = config.appName,
        .FILES_DIRECTORY_NAME = config.filesDirectoryName,
        .DATABASE_NAME = config.databaseName,
        .WARNINGS_FILTER_LEVEL = config.warningsFilter,
        .OTA_MANIFEST_PATH = config.otaManifestPath,
        .NATIVE_DEPENDENCIES = config.nativeDependencies,
        .IS_DEVELOPER_APP = config.isDeveloperApp,
        .CODE_PUSH_KEY= NULL,
        .NATIVE_BINARY_VERSION = [config.nativeBinaryVersion doubleValue],
        .APP_SESSION_ID = config.appSessionId
    });
}

@end
