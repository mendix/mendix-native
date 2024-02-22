#import "UIAlertActionExt.h"
#import "objc/runtime.h"

@implementation UIAlertAction (UIAlertActionExt)

- (void) setAccessibilityIdentifier:(NSString *) accessibilityIdentifier {
  objc_setAssociatedObject(self, @"nsh_AccesibilityIdentifier", accessibilityIdentifier, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *) getAccessibilityIdentifier {
  return (NSString *) objc_getAssociatedObject(self, @"nsh_AccesibilityIdentifier");
}

@end
