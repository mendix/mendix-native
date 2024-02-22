//
//  Copyright (c) Mendix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIAlertAction (UIAlertActionExt)
- (void) setAccessibilityIdentifier:(NSString *) accessabilityIdentifier;
- (NSString *) getAccessibilityIdentifier;
@end
