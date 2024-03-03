#import "MendixApp.h"
#import "DevAppMenu.h"
#import <UIKit/UIKit.h>

@implementation MendixApp

@synthesize identifier;
@synthesize bundleUrl;
@synthesize runtimeUrl;
@synthesize warningsFilter;
@synthesize isDeveloperApp;
@synthesize clearDataAtLaunch;
@synthesize appMenu;
@synthesize splashScreenPresenter;
@synthesize reactLoading;
@synthesize enableThreeFingerGestures;

-(id _Nonnull)init:(NSString * _Nullable)identifier bundleUrl:(NSURL * _Nonnull)bundleUrl runtimeUrl:(NSURL*)runtimeUrl warningsFilter:(WarningsFilter)warningsFilter isDeveloperApp:(BOOL)isDeveloperApp clearDataAtLaunch:(BOOL)clearDataAtLaunch reactLoading:(UIStoryboard * _Nonnull)reactLoading enableThreeFingerGestures:(BOOL)enableThreeFingerGestures {
    self = [self init:identifier bundleUrl:bundleUrl runtimeUrl:runtimeUrl warningsFilter:warningsFilter isDeveloperApp:isDeveloperApp clearDataAtLaunch:clearDataAtLaunch reactLoading:reactLoading];
    self.enableThreeFingerGestures = enableThreeFingerGestures;
    return self;
}
-(id _Nonnull)init:(NSString * _Nullable)identifier bundleUrl:(NSURL * _Nonnull)bundleUrl runtimeUrl:(NSURL*)runtimeUrl warningsFilter:(WarningsFilter)warningsFilter isDeveloperApp:(BOOL)isDeveloperApp clearDataAtLaunch:(BOOL)clearDataAtLaunch  splashScreenPresenter:(id<SplashScreenPresenterProtocol> _Nonnull)splashScreenPresenter enableThreeFingerGestures:(BOOL)enableThreeFingerGestures {
    self = [self init:identifier bundleUrl:bundleUrl runtimeUrl:runtimeUrl warningsFilter:warningsFilter isDeveloperApp:isDeveloperApp clearDataAtLaunch:clearDataAtLaunch splashScreenPresenter:splashScreenPresenter];
    self.enableThreeFingerGestures = enableThreeFingerGestures;
    return self;
}
-(id _Nonnull)init:(NSString * _Nullable)identifier bundleUrl:(NSURL * _Nonnull)bundleUrl runtimeUrl:(NSURL*)runtimeUrl warningsFilter:(WarningsFilter)warningsFilter isDeveloperApp:(BOOL)isDeveloperApp clearDataAtLaunch:(BOOL)clearDataAtLaunch reactLoading:(UIStoryboard * _Nonnull)reactLoading {
    self = [self init:identifier bundleUrl:bundleUrl runtimeUrl:runtimeUrl warningsFilter:warningsFilter isDeveloperApp:isDeveloperApp clearDataAtLaunch:clearDataAtLaunch];
    self.reactLoading = reactLoading;
    return self;
}
-(id _Nonnull)init:(NSString * _Nullable)identifier bundleUrl:(NSURL * _Nonnull)bundleUrl runtimeUrl:(NSURL*)runtimeUrl warningsFilter:(WarningsFilter)warningsFilter isDeveloperApp:(BOOL)isDeveloperApp clearDataAtLaunch:(BOOL)clearDataAtLaunch  splashScreenPresenter:(id<SplashScreenPresenterProtocol> _Nonnull)splashScreenPresenter {
    self = [self init:identifier bundleUrl:bundleUrl runtimeUrl:runtimeUrl warningsFilter:warningsFilter isDeveloperApp:isDeveloperApp clearDataAtLaunch:clearDataAtLaunch];
    self.splashScreenPresenter = splashScreenPresenter;
    return self;
}
-(id _Nonnull)init:(NSString * _Nullable)identifier bundleUrl:(NSURL * _Nonnull)bundleUrl runtimeUrl:(NSURL*)runtimeUrl warningsFilter:(WarningsFilter)warningsFilter isDeveloperApp:(BOOL)isDeveloperApp clearDataAtLaunch:(BOOL)clearDataAtLaunch {
    self = [super init];
    self.identifier = identifier;
    self.bundleUrl = bundleUrl;
    self.runtimeUrl = runtimeUrl;
    self.warningsFilter = warningsFilter;
    self.isDeveloperApp = isDeveloperApp;
    self.clearDataAtLaunch = clearDataAtLaunch;
    self.appMenu = [[DevAppMenu alloc] init];
    self.enableThreeFingerGestures = NO;

    return self;
}

@end
