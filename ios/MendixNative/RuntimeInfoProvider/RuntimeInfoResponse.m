#include "RuntimeInfoResponse.h"

@implementation RuntimeInfoResponse

- (instancetype)initWithStatus:(NSString *)status runtimeInfo:(RuntimeInfo *)runtimeInfo {
  self = [self init];
  if (self) {
    _status = status;
    _runtimeInfo = runtimeInfo;
  }
  return self;
}

@end
