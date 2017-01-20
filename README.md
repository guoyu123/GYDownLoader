# GYDownLoader
GYDownLoader是一个小型下载框架，支持多任务下载，断点续传，开始，暂停，删除等功能
####事例代码
···OC
    [[GYDownLoadManager shareManager] downLoadWithURL:url downLoadProgress:^(float progress) {

        NSLog(@"progress = %lf",progress);
    } success:^(NSString *cacheFilePath, long long totalSize) {

        NSLog(@"success = %@，totalSize = %zd",cacheFilePath,totalSize);
    } falied:^{

        NSLog(@"下载失败");
    }];
···
