@interface RNCAsyncStorage()
- (dispatch_queue_t)methodQueue;
- (void) multiRemove:(NSArray<NSString *> *)keys callback:(RCTResponseSenderBlock)callback;
@end
