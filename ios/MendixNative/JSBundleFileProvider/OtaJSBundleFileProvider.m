//
//  Copyright (c) Mendix, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import "OtaJSBundleFileProvider.h"
#import "OtaHelpers.h"
#import "OtaConstants.h"

@implementation OtaJSBundleFileProvider

+ (NSString *)formatMessage:(NSString *)message {
  return [[[OtaJSBundleFileProvider description] stringByAppendingString:@": "] stringByAppendingString:message];
}

/*
* Returns the OTA bundle's location URL if an OTA bundle has bee downloaded and deployed.
* It:
* 	- Reads the OTA manifest.json
*		- Verifies current app version matches the OTA's deployed app version
*		- Verifies a bundle exists in the location expected
* 	- Returns the absolute path to the OTA bundle if it succeeds
*/
+ (nullable NSURL *)getBundleUrl {
  NSFileManager *manager = [NSFileManager alloc];
  if (![manager fileExistsAtPath:[OtaHelpers getOtaManifestFilepath]]) {
    return nil;
  }

  NSDictionary *manifest = [OtaHelpers readManifestAsDictionary];
  if (manifest == nil) {
  	NSLog(@"No OTA available.");
    return nil;
  }
  
  // If the app version does not match the manifest version we assume the app has been updated/downgraded
  // In this case do not use the OTA bundle.
  if (![[OtaHelpers resolveAppVersion] isEqualToString:manifest[MANIFEST_APP_VERSION_KEY]]) {
  	NSLog(@"Manifest version: %@", manifest[MANIFEST_APP_VERSION_KEY]);
   	NSLog(@"Current version: %@", [OtaHelpers resolveAppVersion]);
    
  	NSLog(@"New app version discovered. Loading default bundle.");
  	return nil;
  }
  
  NSString *relativeBundlePath = manifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY];
  NSString *bundlePath = [OtaHelpers resolveAbsolutePathRelativeToOtaDir:[@"/" stringByAppendingString:relativeBundlePath]];
  if (relativeBundlePath == nil || ![manager fileExistsAtPath:bundlePath]) {
  	NSLog(@"OTA bundle does not exist.");
    return nil;
  }

  return [NSURL URLWithString:[bundlePath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
}

@end
