//
//  GYDownLoadManager.m
//  GYDownLoadLib
//
//  Created by GY on 2016/11/27.
//  Copyright © 2016年 GY. All rights reserved.
//

#import "GYDownLoadManager.h"
#import "NSString+GYDownLoader.h"

@interface GYDownLoadManager()

@property (nonatomic, strong) NSMutableDictionary <NSString *, GYDownLoader *>*downLoadInfo;

@end


@implementation GYDownLoadManager

static GYDownLoadManager *_shareInstance;
+ (instancetype)shareManager {
    
    if (!_shareInstance) {
        _shareInstance = [[GYDownLoadManager alloc] init];
    }
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    
    if (!_shareInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}

- (GYDownLoader *)downLoadWithURL: (NSURL *)url
{
    NSString *md5 = [url.absoluteString md5Str];
    
    GYDownLoader *downLoader = self.downLoadInfo[md5];
    if (downLoader) {
        [downLoader resume];
        return downLoader;
    }
    downLoader = [[GYDownLoader alloc] init];
    [self.downLoadInfo setValue:downLoader forKey:md5];
    
    __weak typeof(self) weakSelf = self;
    [downLoader downLoadWithURL:url downLoadProgress:nil success:^(NSString *cacheFilePath, long long totalSize) {
        
        [weakSelf.downLoadInfo removeObjectForKey:md5];
    } falied:^{
        [weakSelf.downLoadInfo removeObjectForKey:md5];
    }];
    
    return downLoader;
    
}

- (GYDownLoader *)getDownLoaderWithURL: (NSURL *)url {
    NSString *md5 = [url.absoluteString md5Str];
    GYDownLoader *downLoader = self.downLoadInfo[md5];
    return downLoader;
}

- (void)downLoadWithURL:(NSURL *)url downLoadProgress:(downLoadProgress)progress success:(DownLoadSuccessBlock)successBlock falied:(DownLoadFailureBlock)failureBlock{
    
    NSString *md5 = [url.absoluteString md5Str];
    
    GYDownLoader *downLoader = self.downLoadInfo[md5];
    if (downLoader) {
        [downLoader resume];
        return ;
    }
    downLoader = [[GYDownLoader alloc] init];
    [self.downLoadInfo setValue:downLoader forKey:md5];
    
    __weak typeof(self) weakSelf = self;
    [downLoader downLoadWithURL:url downLoadProgress:progress success:^(NSString *cacheFilePath, long long totalSize) {
        
        [weakSelf.downLoadInfo removeObjectForKey:md5];
        if(successBlock){
            successBlock(cacheFilePath,totalSize);
        }
        
    } falied:^{
        [weakSelf.downLoadInfo removeObjectForKey:md5];
        if(failureBlock){
            failureBlock();
        }
    }];
}

- (void)resumeWithURL: (NSURL *)url{
    NSString *md5 = [url.absoluteString md5Str];
    GYDownLoader *downLoader = self.downLoadInfo[md5];
    [downLoader resume];
}

- (void)pauseWithURL: (NSURL *)url {
    
    NSString *md5 = [url.absoluteString md5Str];
    GYDownLoader *downLoader = self.downLoadInfo[md5];
    [downLoader pause];
    
}

- (void)cancelWithURL: (NSURL *)url {
    NSString *md5 = [url.absoluteString md5Str];
    GYDownLoader *downLoader = self.downLoadInfo[md5];
    [downLoader cancel];
}

- (void)cancelAndClearWithURL: (NSURL *)url {
    NSString *md5 = [url.absoluteString md5Str];
    GYDownLoader *downLoader = self.downLoadInfo[md5];
    [downLoader cancelAndClearCache];
}

- (void)pauseAll {
    
    [[self.downLoadInfo allValues] makeObjectsPerformSelector:@selector(pause)];

}

- (void)resumeAll {
    [[self.downLoadInfo allValues] makeObjectsPerformSelector:@selector(resume)];
}

#pragma mark -懒加载
- (NSMutableDictionary *)downLoadInfo {
    if (!_downLoadInfo) {
        _downLoadInfo = [NSMutableDictionary dictionary];
    }
    return _downLoadInfo;
}

@end
