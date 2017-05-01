//
//  JCAudioDownLoader.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/5/1.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "JCAudioDownLoader.h"
#import "JCAudioFileTool.h"

@interface JCAudioDownLoader ()<NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
/** 输出流 */
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSURL *url;
@end

@implementation JCAudioDownLoader

#pragma mark - Public
- (void)downLoadWithURL: (NSURL *)url offset: (long long)offset {

    self.url = url;
    self.offset = offset;
    
    // 取消之间的下载任务
    [self cancelBeforeLoad];
    
    // 开启下载任务
    [self startLoadDataRequest];
}

#pragma mark - NSURLSessionDataDelegate
/**
 *  接收的响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    NSHTTPURLResponse *httpResponse =  (NSHTTPURLResponse *)response;
    
    self.totalSize = [[[httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
    self.contentType = httpResponse.MIMEType;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[JCAudioFileTool tmpPathWithURL:self.url] append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}

/**
 *  接收到数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    
    if ([self.delegate respondsToSelector:@selector(audioDownLoaderIsLoading:)]) {
        [self.delegate audioDownLoaderIsLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error == nil) {
        // 判断, 本地下载的大小, 是否等于文件的总大小
        if ([JCAudioFileTool tmpFileSizeWithURL:self.url] == self.totalSize) {
            [JCAudioFileTool moveTmpPathToCachePath:self.url];
        }
    }
}

#pragma mark - Private
/**
 *  取消之间的下载任务
 */
- (void)cancelBeforeLoad {
    [self.session invalidateAndCancel];
    self.session = nil;
    
    // 清理缓存
    [JCAudioFileTool removeTmpFileWithURL:self.url];
    
    // 重置数据
    self.loadedSize = 0;
}

/**
 *  开启下载任务
 */
- (void)startLoadDataRequest {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", self.offset] forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
}

#pragma mark - Lazy
- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

@end
