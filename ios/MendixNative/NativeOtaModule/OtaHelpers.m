#import "OtaHelpers.h"
#import "OtaConstants.h"
#import "NativeFsModule.h"

@implementation OtaHelpers



#pragma mark - Implementation

+ (NSString *)resolveAppVersion {
    return [[[NSBundle mainBundle].infoDictionary
        objectForKey:@"CFBundleShortVersionString"]
        stringByAppendingString:
            [@"-"
                stringByAppendingString:[[NSBundle mainBundle].infoDictionary
                                            objectForKey:@"CFBundleVersion"]]];
}

+ (NSString *)getOtaDir {
    return [[NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject]
        stringByAppendingString:[@"/" stringByAppendingString:[[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] stringByAppendingString:[@"/" stringByAppendingString:OTA_DIR_NAME]]]];
}

+ (NSString *)getOtaManifestFilepath {
    return
        [OtaHelpers resolveAbsolutePathRelativeToOtaDir:
                             [@"/" stringByAppendingString:MANIFEST_FILE_NAME]];
}

+ (NSString *)resolveAbsolutePathRelativeToOtaDir:(NSString *)path {
    return [[OtaHelpers getOtaDir] stringByAppendingString:path];
}

+ (NSDictionary *)readManifestAsDictionary {
		NSData *contents = [NSData dataWithContentsOfFile:[OtaHelpers getOtaManifestFilepath] options:nil error:nil];
  	if (contents == nil) {
  		return nil;
  	}
  	NSDictionary *jsonOutput = [NSJSONSerialization JSONObjectWithData:contents options:kNilOptions error:nil];
  	if (jsonOutput == nil) {
   	 	return nil;
  	}
   	return jsonOutput;
}

+ (NSDictionary *) getNativeDependencies {
    return [NativeFsModule readJson:[[NSBundle mainBundle] pathForResource:@"native_dependencies" ofType:@"json"] error:nil] ?: @{};
}

@end
