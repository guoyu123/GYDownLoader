//
//  GYDownLoader.m
//  GYDownLoadLib
//
//  Created by GY on 2016/11/26.
//  Copyright © 2016年 GY. All rights reserved.
//

#import "GYDownLoader.h"
#import "NSString+GYDownLoader.h"
#import "GYDownLoaderFileTool.h"

#define kCache NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmp NSTemporaryDirectory()

@interface GYDownLoader ()<NSURLSessionDataDelegate>
{
    // 临时文件的大小
    long long _tmpFileSize;
    // 文件的总大小
    long long _totalFileSize;
}
/** 文件的缓存路径 */
@property (nonatomic, copy) NSString *cacheFilePath;
/** 文件的临时缓存路径 */
@property (nonatomic, copy) NSString *tmpFilePath;
/** 下载会话 */
@property (nonatomic, strong) NSURLSession *session;
/** 文件输出流 */
@property (nonatomic, strong) NSOutputStream *outputStream;
/** 下载任务 */
@property (nonatomic, weak) NSURLSessionDataTask *task;

@property (nonatomic, weak) NSURL *url;

@end


@implementation GYDownLoader


#pragma mark - 接口

+ (NSString *)returnFilePathWithURL: (NSURL *)url {

    NSString *cacheFilePath = [kCache stringByAppendingPathComponent:url.lastPathComponent];

    if([GYDownLoaderFileTool isFileExists:cacheFilePath]) {
        return cacheFilePath;
    }
    return nil;

}
+ (long long)tmpCacheSizeWithURL: (NSURL *)url {

    NSString *tmpFileMD5 = [url.absoluteString md5Str];
    NSString *tmpPath = [kTmp stringByAppendingPathComponent:tmpFileMD5];
    return  [GYDownLoaderFileTool fileSizeWithPath:tmpPath];
}

+ (void)clearCacheWithURL: (NSURL *)url {
    NSString *cachePath = [kCache stringByAppendingPathComponent:url.lastPathComponent];
    [GYDownLoaderFileTool removeFileAtPath:cachePath];
}

- (void)downLoadWithURL:(NSURL *)url downLoadProgress:(downLoadProgress)progress success:(DownLoadSuccessBlock)successBlock falied:(DownLoadFailureBlock)failureBlock{
    
    self.progress = progress;
    self.downLoadSuccess = successBlock;
    self.downLoadfailure = failureBlock;
    
    [self downLoadWithURL:url];
}

- (void)downLoadWithURL: (NSURL *)url {

    self.url = url;
    
    self.cacheFilePath = [kCache stringByAppendingPathComponent:url.lastPathComponent];
    self.tmpFilePath = [kTmp stringByAppendingPathComponent:[url.absoluteString md5Str]];

    if ([GYDownLoaderFileTool isFileExists:self.cacheFilePath]) {
        NSLog(@"文件已经下载完毕, 直接返回相应的数据--文件的具体路径, 文件的大小");
        
        if (self.downLoadfileSize) {
            self.downLoadfileSize([GYDownLoaderFileTool fileSizeWithPath:self.cacheFilePath]);
        }
        
        self.state = GYDownLoaderStateSuccess;
        
        if (self.downLoadSuccessPath) {
            self.downLoadSuccessPath(self.cacheFilePath);
        }
        
        return;
    }

    if ([url isEqual:self.task.originalRequest.URL]) {

        if (self.state == GYDownLoaderStateDowning)
        {
            return;
        }
  
        if (self.state == GYDownLoaderStatePause)
        {
            [self resume];
            return;
        }
    }
    [self cancel];

    _tmpFileSize = [GYDownLoaderFileTool fileSizeWithPath:self.tmpFilePath];
    [self downLoadWithURL:url offset:_tmpFileSize];
}

- (void)resume {
    if (self.state == GYDownLoaderStatePause) {
       [self.task resume];
        self.state = GYDownLoaderStateDowning;
    }
}

- (void)pause {
     if (self.state == GYDownLoaderStateDowning)
     {
        [self.task suspend];
         self.state = GYDownLoaderStatePause;
     }
    
}

- (void)cancel {
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)cancelAndClearCache {
    [self cancel];
 
    [GYDownLoaderFileTool removeFileAtPath:self.tmpFilePath];
    
}



#pragma mark - 私有方法
- (void)downLoadWithURL:(NSURL *)url offset: (long long)offset {

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
    self.task = task;
}


#pragma mark - NSURLSessionDataDelegate 

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    _totalFileSize = [httpResponse.allHeaderFields[@"Content-Length"] longLongValue];
    if (httpResponse.allHeaderFields[@"Content-Range"]) {
        NSString *rangeStr = httpResponse.allHeaderFields[@"Content-Range"] ;
        _totalFileSize = [[[rangeStr componentsSeparatedByString:@"/"] lastObject] longLongValue];
        
    }
    
    if (self.downLoadfileSize) {
        self.downLoadfileSize(_totalFileSize);
    }
  
    if (_tmpFileSize == _totalFileSize) {
        NSLog(@"文件已经下载完成, 移动数据");
        // 移动临时缓存的文件 -> 下载完成的路径
        [GYDownLoaderFileTool moveFile:self.tmpFilePath toPath:self.cacheFilePath];
        self.state = GYDownLoaderStateSuccess;
        // 取消请求
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    if (_tmpFileSize > _totalFileSize) {
        
        NSLog(@"缓存有问题, 删除缓存, 重新下载");
        // 删除缓存
        [GYDownLoaderFileTool removeFileAtPath:self.tmpFilePath];
        
        // 取消请求
        completionHandler(NSURLSessionResponseCancel);
        
        // 重新发送请求  0
        [self downLoadWithURL:response.URL offset:0];
        return;
        
    }
    
    // 继续接收数据,什么都不要处理
    NSLog(@"继续接收数据");
    self.state = GYDownLoaderStateDowning;
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.tmpFilePath append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}


// 接收数据的时候调用
// 100M
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // 进度 = 当前下载的大小 / 总大小
    _tmpFileSize += data.length;
    float progress = 1.0 * _tmpFileSize / _totalFileSize;
    
    if(self.progress){
        self.progress(progress);
    }
    
    [self.outputStream write:data.bytes maxLength:data.length];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self.outputStream close];
    self.outputStream = nil;
    
    if (error == nil) {
        NSLog(@"下载完毕, 成功");
        // 移动数据  temp - > cache
        [GYDownLoaderFileTool moveFile:self.tmpFilePath toPath:self.cacheFilePath];
        self.state = GYDownLoaderStateSuccess;
        if (self.downLoadSuccessPath) {
            self.downLoadSuccessPath(self.cacheFilePath);
        }
        
        if(self.downLoadSuccess)
        {
            self.downLoadSuccess(self.cacheFilePath,_totalFileSize);
        }
        
    }else {
        NSLog(@"有错误---");
        self.state = GYDownLoaderStateFailed;
        if (self.downLoadfailure) {
            self.downLoadfailure();
        }
    }
    
    
}

#pragma mark - 懒加载

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}


- (void)setState:(GYDownLoaderState)state {
    if (_state == state) {
        return;
    }
    _state = state;
    
    if (self.downLoadStateChange) {
        self.downLoadStateChange(state);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kDownLoadURLOrStateChangeNotification object:nil userInfo:@{
                                                                                                                           @"downLoadURL": self.url,
                                                                                                                           @"downLoadState": @(self.state)
                                                                                                                           }];
    
}
@end
