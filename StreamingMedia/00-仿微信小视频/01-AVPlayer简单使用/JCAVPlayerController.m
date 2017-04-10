//
//  JCAVPlayerController.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/4/10.
//  Copyright © 2017年 静持大师. All rights reserved.
//

/*
 * AVPlayer本身并不能显示视频，而且它也不像MPMoviePlayerController有一个view属性。如果AVPlayer要显示必须创建一个
 播放器层AVPlayerLayer用于展示，播放器层继承于CALayer，有了AVPlayerLayer之添加到控制器视图的layer中即可。要使
 用AVPlayer首先了解一下几个常用的类：
 
 * AVAsset：主要用于获取多媒体信息，是一个抽象类，不能直接使用。
 * AVURLAsset：AVAsset的子类，可以根据一个URL路径创建一个包含媒体信息的AVURLAsset对象。
 * AVPlayerItem：一个媒体资源管理对象，管理者视频的一些基本信息和状态，一个AVPlayerItem对应着一个视频资源。
 */


#import "JCAVPlayerController.h"
#import <AVFoundation/AVFoundation.h>

@interface JCAVPlayerController ()
@property (nonatomic, strong) AVPlayer *player;
@end

@implementation JCAVPlayerController

- (void)dealloc {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"AVPlayer";
    
    [self setupAVPlayerLayer];
    
    [self addProgressObserver];
    
    [self addObserverToPlayerItem:self.player.currentItem];
}

/**
 *  创建播放图层
 */
- (void)setupAVPlayerLayer {
    // 通过AVPlayer 创建预览层(AVPlayerLayer)并添加到可视的图层上播放
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.backgroundColor = [UIColor orangeColor].CGColor;
    playerLayer.frame = self.view.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect; // 视频填充模式
    [self.view.layer addSublayer:playerLayer];
    [self.player play];
}

/**
 *  给播放器添加进度更新
 */
-(void)addProgressObserver{
    AVPlayerItem *playerItem = self.player.currentItem;
    //    UIProgressView *progress=self.progress; // 这里设置每秒执行一次
    
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current=CMTimeGetSeconds(time);
        float total=CMTimeGetSeconds([playerItem duration]);
        //        NSLog(@"当前已经播放%.2fs.",current);
        if (current) {
            //            [progress setProgress:(current/total) animated:YES];
            NSLog(@"进度: %f", current/total);
        }
    }];
}

#pragma mark - KVO
/**
 * 给AVPlayerItem添加监控 *
 * @param playerItem AVPlayerItem对象
 */
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}


/**
 * 通过KVO监控播放器状态 *
 * @param keyPath 监控属性
 * @param object 监视器
 * @param change 状态改变
 * @param context 上下文
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem=object;
    if ([keyPath isEqualToString:@"status"]) { // 监控状态属性
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status==AVPlayerStatusReadyToPlay){
            NSLog(@"正在播放...，视频总长度:%.2f",CMTimeGetSeconds(playerItem.duration));
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"]) { // 监控网络加载情况属性
        NSArray *array=playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"共缓冲：%.2f",totalBuffer);
    }
}

#pragma mark - Lazy
- (AVPlayer *)player {
    if (!_player ) {
        // 通过文件 URL 来实例化 AVPlayerItem
        NSString *PATH  = [[NSBundle mainBundle] pathForResource:@"gd.mp4" ofType:nil];
        NSLog(@"李乐强: %@", PATH);
        NSURL *saveUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"gd.mp4" ofType:nil]];
        
        if (saveUrl == nil) {
            NSLog(@"__路径可能不正确__");
        }
        
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:saveUrl];
        
        //
        _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        
        // 可以利用 AVPlayerItem 对这个视频的状态进行监控
    }
    
    return _player;
}

@end

