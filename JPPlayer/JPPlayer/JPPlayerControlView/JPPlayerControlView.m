//
//  JPPlayerControlView.m
//
//  Created by ios app on 16/6/14.
//  Copyright © 2016年 cb2015. All rights reserved.
//

#import "JPPlayerControlView.h"

#define ToolViewShowTime 7
#define KeyPath(objc,keyPath) @(((void)objc.keyPath, #keyPath))

@interface JPPlayerControlView ()
/* 播放器 */
@property (nonatomic, strong) AVPlayer *player;

/** 播放器的Layer（用于显示播放页面） */
@property (weak, nonatomic) AVPlayerLayer *playerLayer;

@property (weak, nonatomic) IBOutlet UIImageView *placeholderImageView;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *fullBtn;

// 记录当前是否显示了工具栏
@property (assign, nonatomic, getter=isShowingToolView) BOOL showingToolView;

/** 定时器 */
@property (nonatomic, strong) NSTimer *progressTimer;

@property (nonatomic, assign) NSInteger hideToolViewSecond;
@property (nonatomic, assign) CGFloat sliderValue;
@end

@implementation JPPlayerControlView

+(instancetype)playerControlView{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];
}

+(instancetype)playerControlViewWithPlayerItem:(AVPlayerItem *)playItem{
    JPPlayerControlView *playerCV = [self playerControlView];
    playerCV.playerItem = playItem;
    return playerCV;
}

-(void)awakeFromNib{
    
    //隐藏工具栏
//    self.toolView.alpha = 0;
    
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"JPPlayerControlView.bundle/Play"] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"JPPlayerControlView.bundle/Pause"] forState:UIControlStateSelected];
    
    [self.fullBtn setImage:[UIImage imageNamed:@"JPPlayerControlView.bundle/full_screen"] forState:UIControlStateNormal];
    [self.fullBtn setImage:[UIImage imageNamed:@"JPPlayerControlView.bundle/full_screen_exit"] forState:UIControlStateSelected];
    
    self.placeholderImageView.image = [UIImage imageNamed:@"JPPlayerControlView.bundle/placeholderImage.jpg"];
    
    //设置滑块进度的图片
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"JPPlayerControlView.bundle/circle"] forState:UIControlStateNormal];
    
    //添加滑块点击监听
    UITapGestureRecognizer *sliderTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderClick:)];
    [self.progressSlider addGestureRecognizer:sliderTapGR];
    
    //添加背景图点击监听
    UITapGestureRecognizer *placeholderTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(placeholderClick:)];
    [self.placeholderImageView addGestureRecognizer:placeholderTapGR];
    
    //添加工具栏点击监听
    UITapGestureRecognizer *toolViewTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toolViewClick:)];
    [self.toolView addGestureRecognizer:toolViewTapGR];
    
    //创建AVPlayer和AVPlayerLayer
    self.player = [[AVPlayer alloc] init];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    //添加到占位图片上（会覆盖掉底层的视图）
    [self.placeholderImageView.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
    
    //监听视频播放结束
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:)name: AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = self.placeholderImageView.bounds;
}

#pragma mark - 监听视频播放结束

-(void)playFinished:(NSNotification *)noti{
    [self removeProgressTimer];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(0.0, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    [self.player pause];
    
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    self.timeLabel.text = [self playTimeStrintWithCurrentTime:0.0 duration:duration];
    
    self.progressSlider.value = 0;
    self.playOrPauseBtn.selected=NO;
}

#pragma mark - 设置视频

-(void)setPlayerItem:(AVPlayerItem *)playerItem{
    
    //先移除观察者
    [_playerItem removeObserver:self forKeyPath:KeyPath(self.playerItem, status)];
    [_playerItem removeObserver:self forKeyPath:KeyPath(self.playerItem, loadedTimeRanges)];
    
    _playerItem = playerItem;
    
    //添加观察者
    [_playerItem addObserver:self forKeyPath:KeyPath(self.playerItem, status) options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:KeyPath(self.playerItem, loadedTimeRanges) options:NSKeyValueObservingOptionNew context:nil];
    
    //替换当前的视频
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    
    [self removeProgressTimer];
    
    self.progressSlider.value = 0;
    self.progressView.progress = 0;
    
    if (playerItem) {
        
        //播放
        [self.player play];
        [self addProgressTimer];
        
        self.playOrPauseBtn.selected = YES;

    } else {
        
        self.playOrPauseBtn.selected = NO;
        
    }
    
}

#pragma mark - KVO监听

//只要监听的属性一改变，就会调用观察者的这个方法，通知你有新值
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if (object == nil) return;
    
    AVPlayerItem *playerItem = object;
    
    /**
     
     *     AVPlayerItemStatusUnknown,播放源未知
     
     *     AVPlayerItemStatusReadyToPlay,播放源准备好
     
     *     AVPlayerItemStatusFailed播放源失败
     
     */
    
    if([keyPath isEqualToString:@"status"]) {
        
        AVPlayerStatus status = [[change objectForKey:@"new"]intValue];
        
        NSLog(@"status %zd",status);
        
        if(status == AVPlayerStatusReadyToPlay){
            
            NSLog(@"正在播放...，视频总长度:%.2f",CMTimeGetSeconds(playerItem.duration));
            
            NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
            
            self.timeLabel.text = [self playTimeStrintWithCurrentTime:0.0 duration:duration];
            
        }
        
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        
        NSArray *array = playerItem.loadedTimeRanges;
        
//        NSLog(@"array = %@", array);
        
        //本次缓冲时间范围
        
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        
        float startSeconds =CMTimeGetSeconds(timeRange.start);
        
        float durationSeconds =CMTimeGetSeconds(timeRange.duration);
        
        //缓冲总长度
        
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        
//        NSLog(@"startSeconds：%.2f",startSeconds);
//        NSLog(@"durationSeconds：%.2f",durationSeconds);
//        
//        NSLog(@"共缓冲：%.2f",totalBuffer);
        
        //更新进度条
        self.progressView.progress = totalBuffer / CMTimeGetSeconds(playerItem.duration);
        
    }
    
}

-(void)dealloc{
    //移除观察者
    [self.playerItem removeObserver:self forKeyPath:KeyPath(self.playerItem, status)];
    [self.playerItem removeObserver:self forKeyPath:KeyPath(self.playerItem, loadedTimeRanges)];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 全屏切换

- (IBAction)switchOrientation:(UIButton *)sender {
    self.hideToolViewSecond = 0;
    
    sender.selected = !sender.selected;
    
    //使用代理切换
    if ([self.delegate respondsToSelector:@selector(switchOrientation:isFull:)]) {
        [self.delegate switchOrientation:self isFull:sender.selected];
    }
}

#pragma mark - 播放 暂停/继续

- (IBAction)playOrPause {
    
    if (self.player.currentItem == nil) return;
    
    self.playOrPauseBtn.selected = !self.playOrPauseBtn.selected;
    
    if (!self.playOrPauseBtn.selected) {
        [self.player pause];             //播放暂停
        [self removeProgressTimer];      //移除计时器
    }else{
        [self.player play];              //播放继续
        [self addProgressTimer];         //添加计时器
    }
    
}

#pragma mark - 播放进度定时器操作

//添加定时器
-(void)addProgressTimer{
    self.hideToolViewSecond = 0;
    
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}

//刷新播放进度
-(void)updateProgressInfo{
    
    //1.刷新时间
    self.timeLabel.text = [self currentPlayTimeStrint];
    
    //2.设置进度条进度
    self.progressSlider.value = CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
    
    /*
     *  CMTime是一个结构体，需要通过CMTimeGetSeconds方法转换
     *  CMTimeGetSeconds：转换 CMTime 为 NSTimeInterval(Float64) 类型
     */
    
    //如果工具栏正在显示且没有任何操作，计算其显示时间，到时间则隐藏
    if (self.toolView.alpha == 1) {
        self.hideToolViewSecond += 1;
        if (self.hideToolViewSecond == ToolViewShowTime) {
            self.hideToolViewSecond = 0;
            [UIView animateWithDuration:0.3 animations:^{
                self.toolView.alpha = 0;
            }];
        }
    }
}

//移除定时器
-(void)removeProgressTimer{
    if (self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
}

#pragma mark - 监听progressSlider的事件处理（监听的是中间滑块）

//开始挪动（touch down）
- (IBAction)startSlide {
    
    //移除定时器
    [self removeProgressTimer];
    
}

//进度值改变（Value Changed）
- (IBAction)slideValueChange {
    //刷新进度显示
    self.sliderValue = self.progressSlider.value;
    
    NSTimeInterval slideTimeInt = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    
    self.timeLabel.text = [self playTimeStrintWithCurrentTime:slideTimeInt duration:duration];
}

//结束挪动（touch up inside、touch up outside）
- (IBAction)endSlide {
    
    /*
     *  这里拿到的self.progressSlider.value是不准确的，所以我用了sliderValue这个属性在调用slideValueChange方法时保存实时的value值
     */
    
    self.progressSlider.value = self.sliderValue;
    
    //获取拖拽位置的时间
    NSTimeInterval slideTimeInt = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    
    //设置【播放的时间】为【拖拽的进度位置】
    [self.player seekToTime:CMTimeMakeWithSeconds(slideTimeInt, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    //播放
    [self.player play];
    self.playOrPauseBtn.selected=YES;
    
    //添加定时器
    [self addProgressTimer];
    
}

#pragma mark - 监听progressSlider的点击事件处理

//给progressSlider添加点击手势，监听点击
- (void)sliderClick:(UITapGestureRecognizer *)sender {
    [self removeProgressTimer];
    
    //获取点击的点
    CGPoint point = [sender locationInView:sender.view];
    
    //获取点击的点在progressSlider宽度的比例
    CGFloat sliderValue = point.x / self.progressSlider.bounds.size.width;
    
    self.progressSlider.value = sliderValue;
    
    //更改播放进度
    NSTimeInterval slideTimeInt = CMTimeGetSeconds(self.player.currentItem.duration) * sliderValue;
    
    [self.player seekToTime:CMTimeMakeWithSeconds(slideTimeInt, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    [self.player play];
    self.playOrPauseBtn.selected=YES;
    
    //添加定时器
    [self addProgressTimer];
}

#pragma mark - 监听placeholder的事件处理（显示或隐藏工具栏）

//给placeholder添加点击手势，监听点击
- (void)placeholderClick:(UITapGestureRecognizer *)sender {
    self.hideToolViewSecond = 0;
    [UIView animateWithDuration:0.3 animations:^{
        if (self.toolView.alpha == 0) {
            self.toolView.alpha = 1;
        }else{
            self.toolView.alpha = 0;
        }
    }];
}

#pragma mark - 监听toolView的事件处理（重置工具栏显示时间）

- (void)toolViewClick:(UITapGestureRecognizer *)sender {
    self.hideToolViewSecond = 0;
}


#pragma mark - 解析当前播放时间为字符串

-(NSString *)currentPlayTimeStrint{
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    return [self playTimeStrintWithCurrentTime:currentTime duration:duration];
}

-(NSString *)playTimeStrintWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration{
    
    NSInteger currentMin = currentTime / 60;
    NSInteger currentSec = (NSInteger)currentTime % 60;
    
    NSInteger durationMin = duration / 60;
    NSInteger durationSec = (NSInteger)duration % 60;
    
    if (currentMin < 0) currentMin = 0;
    if (currentSec < 0) currentSec = 0;
    if (durationMin < 0) durationMin = 0;
    if (durationSec < 0) durationSec = 0;
    
    return [NSString stringWithFormat:@"%02zd:%02zd/%02zd:%02zd", currentMin, currentSec, durationMin, durationSec];
}

//-(void)setHideToolViewSecond:(NSInteger)hideToolViewSecond{
//    _hideToolViewSecond = hideToolViewSecond;
//    
//    if (hideToolViewSecond == 0) {
//        NSLog(@"已重置");
//    }
//    
//    if (hideToolViewSecond == ToolViewShowTime) {
//        NSLog(@"时间到");
//    }
//    
//}

@end
