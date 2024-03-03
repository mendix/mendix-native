//
//  Copyright (c) Mendix, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "NativeDownloadHandler.h"
#import <React/RCTEventEmitter.h>

@implementation NativeDownloadHandler

+ (NSString *) formatMessage:(NSString *)message {
  return [[[NativeDownloadHandler description] stringByAppendingString:@": "] stringByAppendingString:message];
}

- (id)init:(NSDictionary *) config doneCallback:(void (^)(void))doneCallback
      progressCallback:(void (^)(long long, long long)) progressCallback
          failCallback:(void (^)(NSError *err))failCallback {
  self.mimeType = config[@"mimeType"];
  self.connectionTimeout = [((NSNumber *) config[@"connectionTimeout"] ?: [NSNumber numberWithInt: 10000]) intValue] / 1000;
  self.doneCallback = doneCallback;
  self.progressCallback = progressCallback;
  self.failCallback = failCallback;
  return self;
}

- (void)download:(NSString *)urlString downloadPath:(NSString *)downloadPath {
  self.downloadPath = downloadPath;

  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                        delegate:self
                                                   delegateQueue:nil];
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                       timeoutInterval:self.connectionTimeout];
  [[session downloadTaskWithRequest:request] resume];
}

#pragma mark NSURLSession Delegate Methods

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
  NSError *fileError;
  NSFileManager *manager = [NSFileManager defaultManager];
  
	if (self.mimeType != nil && downloadTask.response.MIMEType != self.mimeType) {
		NSError *error = [NSError errorWithDomain:NSArgumentDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"MIME type not expected."}];
		self.failCallback(error);
  }

  if ([manager fileExistsAtPath:[self downloadPath]]) {
      NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"File already exists in the same path."}];
      self.failCallback(error);
      return;
  }

  NSURL *directoryUrl = [NSURL fileURLWithPath:[[self downloadPath] stringByDeletingLastPathComponent]];
  [manager createDirectoryAtURL:directoryUrl withIntermediateDirectories:YES attributes:nil error:&fileError];
  if (fileError != nil) {
    NSLog([NativeDownloadHandler formatMessage:@"Could not create path: %@"], fileError);
    self.failCallback(fileError);
    return;
  }

  NSURL *url = [NSURL fileURLWithPath:[self downloadPath]];
  [manager replaceItemAtURL:url withItemAtURL:location backupItemName:[[[self downloadPath] lastPathComponent] stringByAppendingString:@"_backup"] options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:nil error:&fileError];
  if (fileError != nil) {
  	[manager removeItemAtURL:url error:nil];
    NSLog([NativeDownloadHandler formatMessage:@"Could not copy path: %@"], fileError);
    self.failCallback(fileError);
    return;
  }

  NSLog(@"%@", [NativeDownloadHandler formatMessage:@"File saved successfully"]);
  self.doneCallback();
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
  NSLog(@"%@", [NSString localizedStringWithFormat:[NativeDownloadHandler formatMessage:@"Bytes written %d"], totalBytesWritten]);
  if (self.progressCallback != nil)
  	self.progressCallback(totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didCompleteWithError:(NSError *)error {
  if (!error) return;

  NSLog([NativeDownloadHandler formatMessage:@"Could not download: %@"], error);
  self.failCallback(error);
}

@end

@implementation NativeDownloadModule

RCT_EXPORT_MODULE()

NSString *ERROR_DOWNLOAD_FAILED = @"ERROR_DOWNLOAD_FAILED";
NSString *DOWNLOAD_PROGRESS_EVENT = @"NativeDownloadModuleDownloadProgress";

RCT_EXPORT_METHOD(download:(NSString *)url downloadPath:(NSString *)downloadPath config:(NSDictionary *)config resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
    NativeDownloadHandler *handler = [[NativeDownloadHandler alloc] init:config doneCallback: ^() {
      resolve(nil);
    } progressCallback:^(long long received, long long total) {
      [self sendEventWithName: DOWNLOAD_PROGRESS_EVENT body: @{
        @"receivedBytes": [NSNumber numberWithLongLong: received],
        @"totalBytes": [NSNumber numberWithLongLong: total]}];
    } failCallback:^(NSError *error) {
      reject(ERROR_DOWNLOAD_FAILED, [NativeDownloadHandler formatMessage:[error localizedDescription]], error);
    }];
    [handler download:url downloadPath:downloadPath];
  } @catch(NSError *error) {
    return reject(ERROR_DOWNLOAD_FAILED, [NativeDownloadHandler formatMessage:@"Failed to download file"], error);
  }
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[DOWNLOAD_PROGRESS_EVENT];
}

@end
