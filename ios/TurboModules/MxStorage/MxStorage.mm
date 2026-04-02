#import "MxStorage.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxStorage

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxStorageSpecJSI>(params);
}

- (void)clearDatabases:(RCTPromiseResolveBlock)resolve
                reject:(RCTPromiseRejectBlock)reject {
    // NOTE: Using self.bridge for OPSQLite module access
    // TODO: Move to JavaScript orchestration - JavaScript can call OPSQLite TurboModule directly
    // if it exposes deleteAllDBs() method. This would eliminate native module lookup entirely.
    id opSQLiteModule = [self.bridge moduleForName:@"OPSQLite"];

    if (!opSQLiteModule) {
        reject(@"MODULE_NOT_FOUND", @"OPSQLiteModule not available", nil);
        return;
    }

    SEL deleteAllSelector = NSSelectorFromString(@"deleteAllDBs");
    if ([opSQLiteModule respondsToSelector:deleteAllSelector]) {
        [opSQLiteModule performSelector:deleteAllSelector];
        resolve(nil);
    } else {
        reject(@"METHOD_NOT_FOUND", @"deleteAllDBs method not available on OPSQLite", nil);
    }
}

- (void)closeDatabaseConnections:(RCTPromiseResolveBlock)resolve
                          reject:(RCTPromiseRejectBlock)reject {
    // NOTE: Using self.bridge for OPSQLite module access
    // TODO: Move to JavaScript orchestration - JavaScript can call OPSQLite TurboModule directly
    // if it exposes closeAllConnections() method. This would eliminate native module lookup entirely.
    id opSQLiteModule = [self.bridge moduleForName:@"OPSQLite"];

    if (!opSQLiteModule) {
        reject(@"MODULE_NOT_FOUND", @"OPSQLiteModule not available", nil);
        return;
    }

    SEL closeAllSelector = NSSelectorFromString(@"closeAllConnections");
    if ([opSQLiteModule respondsToSelector:closeAllSelector]) {
        [opSQLiteModule performSelector:closeAllSelector];
        resolve(nil);
    } else {
        reject(@"METHOD_NOT_FOUND", @"closeAllConnections method not available on OPSQLite", nil);
    }
}

@end
