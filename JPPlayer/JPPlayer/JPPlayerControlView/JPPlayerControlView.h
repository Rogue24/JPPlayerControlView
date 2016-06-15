//
//  JPPlayerControlView.h
//
//  Created by ios app on 16/6/14.
//  Copyright © 2016年 cb2015. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "JPPlayerFullViewController.h"
@class JPPlayerControlView;

@protocol JPPlayerControlViewDelegate <NSObject>

@optional
-(void)switchOrientation:(JPPlayerControlView *)playerControlView isFull:(BOOL)isFull;

@end

@interface JPPlayerControlView : UIView

+(instancetype)playerControlView;

+(instancetype)playerControlViewWithPlayerItem:(AVPlayerItem *)playItem;

@property (nonatomic,strong) AVPlayerItem *playerItem;

@property (nonatomic,weak) id <JPPlayerControlViewDelegate> delegate;

@end
