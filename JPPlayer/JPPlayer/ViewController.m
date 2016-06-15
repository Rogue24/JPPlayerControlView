//
//  ViewController.m
//
//  Created by ios app on 16/6/14.
//  Copyright © 2016年 cb2015. All rights reserved.
//

/*
 
 MP3远程链接
 http://cc.stream.qqmusic.qq.com/C100003j8IiV1X8Oaw.m4a?fromtag=52
 
 视频链接
 http://v1.mukewang.com/19954d8f-e2c2-4c0a-b8c1-a4c826b5ca8b/L.mp4
 http://v1.mukewang.com/3e35cbb0-c8e5-4827-9614-b5a355259010/L.mp4
 http://v1.mukewang.com/a45016f4-08d6-4277-abe6-bcfd5244c201/L.mp4
 
 */

#import "ViewController.h"
#import "JPPlayerControlView.h"

@interface ViewController () <JPPlayerControlViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (nonatomic, weak) JPPlayerControlView *playerCV;
@property (nonatomic, strong) JPPlayerFullViewController *fullVC;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://v1.mukewang.com/19954d8f-e2c2-4c0a-b8c1-a4c826b5ca8b/L.mp4"]];
    
    JPPlayerControlView *playerCV = [JPPlayerControlView playerControlViewWithPlayerItem:item];
    playerCV.delegate = self;
    
    [self.playerView addSubview:playerCV];
    
    self.playerCV = playerCV;
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.playerCV.frame = self.playerView.bounds;
}

- (IBAction)video1:(id)sender {
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://v1.mukewang.com/19954d8f-e2c2-4c0a-b8c1-a4c826b5ca8b/L.mp4"]];
    self.playerCV.playerItem = item;
}

- (IBAction)video2:(id)sender {
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://v1.mukewang.com/3e35cbb0-c8e5-4827-9614-b5a355259010/L.mp4"]];
    self.playerCV.playerItem = item;
}

- (IBAction)video3:(id)sender {
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://v1.mukewang.com/a45016f4-08d6-4277-abe6-bcfd5244c201/L.mp4"]];
    self.playerCV.playerItem = item;
}


-(JPPlayerFullViewController *)fullVC{
    if (!_fullVC) {
        _fullVC = [[JPPlayerFullViewController alloc] init];
    }
    return _fullVC;
}

#pragma mark - JPPlayerControlViewDelegate

-(void)switchOrientation:(JPPlayerControlView *)playerControlView isFull:(BOOL)isFull{
    
    /*
     
        全屏显示：需要推出一个新的全屏控制器（设置成横屏显示），再将视频页面放到新控制器的view上
        
        addSubview ---> 将视频页面添加到新的页面上，就会自动从原来的页面上移除
     
     */
    
    if (isFull) {
        [self presentViewController:self.fullVC animated:NO completion:^{
            [UIView animateWithDuration:0.25 animations:^{
                self.playerCV.frame = self.fullVC.view.bounds;
                [self.fullVC.view addSubview:self.playerCV];
            }];
        }];
    } else {
        [self.fullVC dismissViewControllerAnimated:NO completion:^{
            [UIView animateWithDuration:0.25 animations:^{
                self.playerCV.frame = self.playerView.bounds;
                [self.playerView addSubview:self.playerCV];
            }];
        }];
    }
}

@end
