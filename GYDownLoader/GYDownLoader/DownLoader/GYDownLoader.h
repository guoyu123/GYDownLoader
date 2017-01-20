//
//  GYDownLoader.h
//  GYDownLoadLib
//
//  Created by GY on 2016/11/26.
//  Copyright © 2016年 GY. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDownLoadURLOrStateChangeNotification @"downLoadURLOrStateChangeNotification"

typedef enum : NSUInteger {
    
    GYDownLoaderStateUnKnown,
    /** 下载暂停 */
    GYDownLoaderStatePause,
    /** 正在下载 */
    GYDownLoaderStateDowning,
    /** 已经下载 */
    GYDownLoaderStateSuccess,
    /** 下载失败 */
    GYDownLoaderStateFailed
    
} GYDownLoaderState;


typedef void(^DownLoadFileSize)(long long fileSize);
typedef void(^DownLoadSuccessPathBlock)(NSString *cacheFilePath);
typedef void(^DownLoadFailureBlock)();
typedef void(^DownLoadSuccessBlock)(NSString *cacheFilePath, long long totalSize);
typedef void(^downLoadProgress)(float progress);

@interface GYDownLoader : NSObject
/** 状态 */
@property (nonatomic, assign, readonly) GYDownLoaderState state;

/** 下载进度 */
@property (nonatomic, copy) downLoadProgress progress;

/** 文件下载信息 (下载的大小) */
@property (nonatomic, copy) DownLoadFileSize downLoadfileSize;

/** 状态的改变 */
@property (nonatomic, copy) void(^downLoadStateChange)(GYDownLoaderState state);

/** 下载成功 (成功路径) */
@property (nonatomic, copy) DownLoadSuccessPathBlock downLoadSuccessPath;

/** 下载成功 (文件大小) */
@property (nonatomic, copy) DownLoadSuccessBlock downLoadSuccess;

/** 失败 (错误信息) */
@property (nonatomic, copy) DownLoadFailureBlock downLoadfailure;

+ (NSString *)returnFilePathWithURL: (NSURL *)url;
+ (long long)tmpCacheSizeWithURL: (NSURL *)url;
+ (void)clearCacheWithURL: (NSURL *)url;

/** 如果当前已经下载, 继续下载, 如果没有下载, 从头开始下载 */
- (void)downLoadWithURL: (NSURL *)url;

/** 下载，返回下载进度，成功回调（文件总大小，当前下载文件大小），失败回调 */
- (void)downLoadWithURL:(NSURL *)url downLoadProgress:(downLoadProgress)progress success:(DownLoadSuccessBlock)successBlock falied:(DownLoadFailureBlock)failureBlock;

/** 恢复下载 */
- (void)resume;

/** 暂停, 暂停任务, 可以恢复, 缓存没有删除 */
- (void)pause;

/** 取消 */
- (void)cancel;

/** 缓存删除 */
- (void)cancelAndClearCache;

@end
