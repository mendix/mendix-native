#import "RuntimeInfo.h"

@implementation RuntimeInfo

- (instancetype) initWithVersion:(NSString *)version cacheburst:(NSString *)cacheburst nativeBinaryVersion:(long)nativeBinaryVersion packagerPort:(long)packagerPort {
  self = [super init];
  if (self) {
    _version = version;
    _nativeBinaryVersion = nativeBinaryVersion;
    _packagerPort = packagerPort;
    _cacheburst = cacheburst;
  }
  return self;
}

@end
