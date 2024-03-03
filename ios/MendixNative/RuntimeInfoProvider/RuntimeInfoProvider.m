# import "RuntimeInfoProvider.h"

@implementation RuntimeInfoProvider

+ (void) getRuntimeInfo:(NSURL *)runtimeURL completionHandler:(void (^)(RuntimeInfoResponse *response))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:runtimeURL];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval: 10];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:[@"{\"action\": \"info\"}" dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
          return [RuntimeInfoProvider runCallBackInMainThread:[RuntimeInfoProvider makeInaccessibleResponse] completionHandler: completionHandler];
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if (![RuntimeInfoProvider IsSuccessStatusCode: httpResponse.statusCode]) {
          return [RuntimeInfoProvider runCallBackInMainThread:[RuntimeInfoProvider makeFailedResponse] completionHandler:completionHandler];
        }
        
        NSError *parsingError = nil;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parsingError];
        if (parsingError != nil) {
          return [RuntimeInfoProvider runCallBackInMainThread:[RuntimeInfoProvider makeFailedResponse] completionHandler: completionHandler];
        }
        RuntimeInfo *runtimeInfo = [RuntimeInfoProvider runtimeInfoFromJSONDictionary:jsonDictionary];
      
      return [RuntimeInfoProvider runCallBackInMainThread:[RuntimeInfoProvider makeSuccessResponse:runtimeInfo] completionHandler: completionHandler];
       
    }] resume];
}

+ (void) runCallBackInMainThread:(RuntimeInfoResponse *)response completionHandler:(void (^)(RuntimeInfoResponse *response))completionHandler {
  dispatch_async(dispatch_get_main_queue(), ^{
    completionHandler(response);
  });
}

+ (RuntimeInfoResponse *) makeInaccessibleResponse {
    return  [[RuntimeInfoResponse alloc] initWithStatus:@"INACCESSIBLE" runtimeInfo:nil];
}

+ (RuntimeInfoResponse *) makeFailedResponse {
    return  [[RuntimeInfoResponse alloc] initWithStatus:@"FAILED" runtimeInfo:nil];
}

+ (RuntimeInfoResponse *) makeSuccessResponse:(RuntimeInfo *)runtimeInfo {
    return  [[RuntimeInfoResponse alloc] initWithStatus:@"SUCCESS" runtimeInfo:runtimeInfo];
}

+ (BOOL) IsSuccessStatusCode:(long)statusCode
{
    return (statusCode >= 200) && (statusCode <= 299);
}

+ (RuntimeInfo *) runtimeInfoFromJSONDictionary:(NSDictionary *) dictionary {
  return [[RuntimeInfo alloc] initWithVersion:dictionary[@"version"] cacheburst:dictionary[@"cachebust"] nativeBinaryVersion:[dictionary[@"nativeBinaryVersion"] longValue] packagerPort:[dictionary[@"packagerPort"] longValue]];
}

@end
