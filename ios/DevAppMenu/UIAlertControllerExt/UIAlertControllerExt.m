#import "UIAlertControllerExt.h"
#import "UIAlertActionExt.h"

@implementation UIAlertController (UIAlertControllerExt)

- (void) applyAccessibilityIdentifiers {
    for (UIAlertAction *action in self.actions) {
        id label = [action valueForKey:@"__representer"];
        UIView *view = (UIView *)label;
        view.accessibilityIdentifier = [action getAccessibilityIdentifier];
    }
}

@end
