#include "UnsupportedFeatures.h"

@implementation UnsupportedFeatures
@synthesize reloadInClient;
@synthesize hideSplashScreenInClient;

- (id)init:(BOOL)reloadInClientNotSupported {
    self.reloadInClient = reloadInClientNotSupported;
    return self;
}

- (id)init:(BOOL)reloadInClientNotSupported hideSplashScreenInClient:(BOOL)hideSplashScreenInClientNotSupported {
    self = [self init:reloadInClientNotSupported];
    self.hideSplashScreenInClient = hideSplashScreenInClientNotSupported;
    return self;
}

@end
