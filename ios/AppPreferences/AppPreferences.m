#import "AppPreferences.h"
#import "WarningsFilter.h"
#import "AppUrl.h"

@implementation AppPreferences
NSString *appUrlKey = @"ApplicationUrl";
NSString *devModeEnabledKey = @"DevModeEnabled";
NSString *clearDataEnabledKey = @"ClearData";
NSString *remoteDebuggingEnabledKey = @"RemoteDebuggingEnabled";
NSString *remoteDebuggingPackagerPortKey = @"RemoteDebuggingPackagerPort";
NSString *elementInspectorDebugKey = @"showInspector";

+ (NSString*) getAppUrl {
    return [[NSUserDefaults standardUserDefaults] stringForKey:appUrlKey];
}

+ (void) setAppUrl:(NSString*) url {
    [[NSUserDefaults standardUserDefaults] setObject:url forKey:appUrlKey];
}

+ (BOOL) devModeEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:devModeEnabledKey];
}

+ (void) devMode:(BOOL)enable {
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:devModeEnabledKey];
}

+ (BOOL) remoteDebuggingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:remoteDebuggingEnabledKey];
}

+ (void) remoteDebugging:(BOOL)enable {
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:remoteDebuggingEnabledKey];
}

+ (int) getRemoteDebuggingPackagerPort {
    int port = (int) [[NSUserDefaults standardUserDefaults] integerForKey:remoteDebuggingPackagerPortKey];
    return port != 0 ? port : [AppUrl defaultPackagerPort];
}

+ (void) setRemoteDebuggingPackagerPort: (NSInteger)port {
    [[NSUserDefaults standardUserDefaults] setInteger:port forKey:remoteDebuggingPackagerPortKey];
}

+ (BOOL) isElementInspectorEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:elementInspectorDebugKey];
}

+ (void) setElementInspector:(BOOL)enable {
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:elementInspectorDebugKey];
}

@end
