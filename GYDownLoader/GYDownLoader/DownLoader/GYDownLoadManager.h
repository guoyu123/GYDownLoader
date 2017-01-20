//
//  GYDownLoadManager.h
//  GYDownLoadLib
//
//  Created by GY on 2016/11/27.
//  Copyright © 2016年 GY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYDownLoader.h"

@interface GYDownLoadManager : NSObject

+ (instancetype)shareManager;

/** 根据URL下载资源 */
- (GYDownLoader *)downLoadWithURL: (NSURL *)url;

/** 获取url对应的downLoader */
- (GYDownLoader *)getDownLoaderWithURL: (NSURL *)url;

/** 下载，返回下载进度，成功回调（文件总大小，当前下载文件大小），失败回调 */
- (void)downLoadWithURL:(NSURL *)url downLoadProgress:(downLoadProgress)progress success:(DownLoadSuccessBlock)successBlock falied:(DownLoadFailureBlock)failureBlock;

/** 根据URL恢复资源 */
- (void)resumeWithURL: (NSURL *)url;

/** 根据URL暂停资源 */
- (void)pauseWithURL: (NSURL *)url;

/** 根据URL取消资源 */
- (void)cancelWithURL: (NSURL *)url;

/** 根据URL取消资源,并清空缓存 */
- (void)cancelAndClearWithURL: (NSURL *)url;

/** 暂停所有 */
- (void)pauseAll;

/** 恢复所有 */
- (void)resumeAll;

@end
