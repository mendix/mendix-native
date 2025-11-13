#import <MendixNativeSpec/MendixNativeSpec.h>
#import <React/RCTReloadCommand.h>
#import "RNCAsyncStorage.h"
#import "RCTAppDelegate.h"

@interface MendixNative : NativeMendixNativeSpecBase <NativeMendixNativeSpec>
- (void)reloadClientWithState;
@end
