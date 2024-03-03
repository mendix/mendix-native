#import "MendixBackwardsCompatUtility.h"
#import <math.h>

NSDictionary<NSString *, UnsupportedFeatures *> *versionDictionary;

@implementation MendixBackwardsCompatUtility

static UnsupportedFeatures * unsupportedFeatures;

+ (void) load {
    versionDictionary = @{
        @"8.9": [[UnsupportedFeatures alloc] init:YES hideSplashScreenInClient:YES],
        @"8.10": [[UnsupportedFeatures alloc] init:NO hideSplashScreenInClient:YES],
        @"8.11": [[UnsupportedFeatures alloc] init:NO hideSplashScreenInClient:YES],
        @"8.12.0": [[UnsupportedFeatures alloc] init:NO hideSplashScreenInClient:YES],
        @"DEFAULT": [[UnsupportedFeatures alloc] init:NO hideSplashScreenInClient:NO]
    };
}

+ (NSDictionary *) versionDictionary {
    @synchronized (self) {
        return versionDictionary;
    }
}

+ (UnsupportedFeatures *)unsupportedFeatures {
    @synchronized (self) {
        return unsupportedFeatures;
    }
}

+ (void)update:(NSString *)forVersion {
    NSArray *versionParts = [forVersion componentsSeparatedByString:@"."];
    unsupportedFeatures = [versionDictionary objectForKey:[[versionParts subarrayWithRange: NSMakeRange(0, fmin(versionParts.count, 3))] componentsJoinedByString:@"."]] ? : [versionDictionary objectForKey:[[versionParts subarrayWithRange: NSMakeRange(0, fmin(versionParts.count - 1, 2))] componentsJoinedByString:@"."]] ?: [versionDictionary objectForKey:versionParts[0]] ?: [versionDictionary objectForKey:@"DEFAULT"];
}
@end
