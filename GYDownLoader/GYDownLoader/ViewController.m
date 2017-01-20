//
//  ViewController.m
//  GYDownLoader
//
//  Created by 果雨 on 2017/1/20.
//  Copyright © 2017年 xxx. All rights reserved.
//

#import "ViewController.h"
#import "GYDownLoadManager.h"

@interface ViewController ()
@property (nonatomic , strong) NSURL *url;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)begin:(UIButton *)sender {
    
    NSURL *url = [NSURL URLWithString:@"http://free2.macx.cn:8281/tools/photo/Sip44.dmg"];
    
    self.url = url;
    [[GYDownLoadManager shareManager] downLoadWithURL:url downLoadProgress:^(float progress) {
        NSLog(@"progress = %lf",progress);
    } success:^(NSString *cacheFilePath, long long totalSize) {
        NSLog(@"success = %@，totalSize = %zd",cacheFilePath,totalSize);
    } falied:^{
        NSLog(@"下载失败");
    }];
}

- (IBAction)resume:(UIButton *)sender {
    
    [[GYDownLoadManager shareManager] resumeWithURL:self.url];
}
- (IBAction)pause:(UIButton *)sender {
    
    [[GYDownLoadManager shareManager] pauseWithURL:self.url];
}
- (IBAction)cancel:(UIButton *)sender {
    
    [[GYDownLoadManager shareManager] cancelWithURL:self.url];
}

@end
