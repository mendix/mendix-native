#import "AppUrl.h"

@implementation AppUrl

static int _defaultPackagerPort = 8083;

static NSString const * queryStringForDevMode = @"platform=ios&dev=true&minify=false";
static NSString const * queryString = @"platform=ios&dev=false&minify=true";
static NSString const * defaultUrl = @"http://localhost:8080";
static NSString const * bundlePath = @"/index.bundle";

+ (int) defaultPackagerPort {
    return _defaultPackagerPort;
}

+ (NSURL *) forBundle:(NSString*)url port:(int)port isDebuggingRemotely:(BOOL)isDebuggingRemotely isDevModeEnabled:(BOOL)isDevModeEnabled {
    NSURLComponents *urlComponents = [self createUrlComponents:url];
    [urlComponents setPort:[[NSNumber alloc] initWithInt:(port != 0 ? port :  _defaultPackagerPort)]];
    [urlComponents setPath:[[urlComponents path] stringByAppendingString:bundlePath]];
    
    [urlComponents setQuery:(isDevModeEnabled ? queryStringForDevMode : queryString)];
    
    return [urlComponents URL];
}

+ (NSURL *) forRuntime:(NSString*)url {
    NSURLComponents *urlComponents = [self createUrlComponents:url];
    [urlComponents setPath:@"/"];
    
    return [[NSURL alloc] initWithString:[urlComponents string]];
}

+ (NSURL *) forValidation:(NSString*)url {
    NSURLComponents *urlComponents = [self createUrlComponents:url];
    [urlComponents setPath:@"/components.json"];
    
    return [[NSURL alloc] initWithString:[urlComponents string]];
}

+ (NSURL *) forRuntimeInfo:(NSString*)url {
    NSURLComponents *urlComponents = [self createUrlComponents:url];
    [urlComponents setPath:@"/xas/"];
    
    return [[NSURL alloc] initWithString:[urlComponents string]];
}

+ (NSURL *) forPackagerStatus:(NSString*)url port:(int) port {
    NSURLComponents *urlComponents = [self createUrlComponents:url];
    [urlComponents setPath:@"/status"];
    [urlComponents setPort:[[NSNumber alloc] initWithInt:(port != 0 ? port :  _defaultPackagerPort)]];
    
    return [[NSURL alloc] initWithString:[urlComponents string]];
}

+ (BOOL) isValid:(NSString *)url {
    if ([[url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] < 1) {
        return NO;
    }
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:[self ensureProtocol:[self removeTrailingSlash: url]]];
    
    return urlComponents != nil && ([urlComponents queryItems] == nil || [[urlComponents queryItems] count] == 0) && [[urlComponents path] length] < 1;
}

+ (NSURLComponents *) createUrlComponents:(NSString*)url {
    NSString *appUrl = [self ensureProtocol: [self removeTrailingSlash: url]];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:appUrl];
    
    return components == nil ? [[NSURLComponents alloc] initWithString: defaultUrl] : components;
}

+ (NSString *) ensureProtocol:(NSString *)url {
  return [url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] ? url : [@"http://" stringByAppendingString:url];
}

+ (NSString *) removeTrailingSlash:(NSString *)url {
    NSString *spaceTrimmedUrl = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return [spaceTrimmedUrl hasSuffix:@"/"] ? [spaceTrimmedUrl substringToIndex:[spaceTrimmedUrl length] - 1]:spaceTrimmedUrl;
}

@end
