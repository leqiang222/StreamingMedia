//
//  JCRemotePlayer.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/5/1.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "JCRemotePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "JCResourceLoader.h"
#import "NSURL+Audio.h"

static JCRemotePlayer *_shareInstance;

@interface JCRemotePlayer () {
    BOOL _isUserPause; // 是否是用户暂停播放的
}
@property (nonatomic, strong) AVPlayer *player;
/**
 资源加载代理
 */
@property (nonatomic, strong) JCResourceLoader *resourceLoader;
@end

@implementation JCRemotePlayer
#pragma mark - 单例方法
+ (instancetype)shareInstance {
    if (!_shareInstance) {
        _shareInstance = [[JCRemotePlayer alloc] init];
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

- (id)copyWithZone:(NSZone *)zone {
    return _shareInstance;
}

-(id)mutableCopyWithZone:(NSZone *)zone {
    return _shareInstance;
}


#pragma mark - Public
- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache {
    
    NSURL *currentURL = [(AVURLAsset *)self.player.currentItem.asset URL];
    if ([url isEqual:currentURL] || [[url kl_streamingURL] isEqual:currentURL]) {
        NSLog(@"/remoteAudio/-------- 当前播放任务已经存在 --------/remoteAudio/");
        // 继续播放
        [self resume];
        return;
    }
    
    // 创建一个播放器对象
    // 如果我们使用这样的方法, 去播放远程音频
    // 这个方法, 系统已经帮我们封装了三个步骤 1. 资源的请求; 2. 资源的组织; 3. 给播放器, 资源的播放
    // 如果资源加载比较慢, 有可能, 会造成调用了play方法, 但是当前并没有播放音频
    if (self.player.currentItem) {
        [self removeObserver];
    }
    
    _url = url;
    
    if (isCache) {
        url = [url kl_streamingURL];
    }
    
    // 1. 资源的请求
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    // 关于网络音频的请求, 是通过这个对象, 调用代理的相关方法, 进行加载的
    // 拦截加载的请求, 只需要, 重新修改它的代理方法就可以
    self.resourceLoader = [JCResourceLoader new];
    [asset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
    
    // 2. 资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    // 当资源的组织者, 告诉我们资源准备好了之后, 我们再播放
    // AVPlayerItemStatus status
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playInterupt) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    // 3. 资源的播放
    self.player = [AVPlayer playerWithPlayerItem:item];
}

- (void)pause {
    [self.player pause];
    _isUserPause = YES;
    if (self.player) {
        self.state = JCRemotePlayerStatePause;
    }
}

- (void)resume {
    [self.player play];
    _isUserPause = NO;
    // 就是代表,当前播放器存在, 并且, 数据组织者里面的数据准备, 已经足够播放了
    if (self.player && self.player.currentItem.playbackLikelyToKeepUp) {
        self.state = JCRemotePlayerStatePlaying;
    }
}

- (void)stop {
    [self.player pause];
    self.player = nil;
    if (self.player) {
        self.state = JCRemotePlayerStateStopped;
    }
}

- (void)seekWithProgress:(float)progress {
    
    if (progress < 0 || progress > 1) {
        return;
    }
    
    // 可以指定时间节点去播放
    // 时间: CMTime : 影片时间
    // 影片时间 -> 秒
    // 秒 -> 影片时间
    
    // 1. 当前音频资源的总时长
    CMTime totalTime = self.player.currentItem.duration;
    // 2. 当前音频, 已经播放的时长
    //    self.player.currentItem.currentTime
    NSTimeInterval totalSec = CMTimeGetSeconds(totalTime);
    NSTimeInterval playTimeSec = totalSec * progress;
    CMTime currentTime = CMTimeMake(playTimeSec, 1);
    
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"/remoteAudio/-------- 确定加载这个时间点的音频资源 --------/remoteAudio/");
        }else {
            NSLog(@"/remoteAudio/-------- 取消加载这个时间点的音频资源 --------/remoteAudio/");
        }
    }];
}

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer {
    
    // 1. 当前音频资源的总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    // 2. 当前音频, 已经播放的时长
    
    NSTimeInterval playTimeSec = [self currentTime];
    playTimeSec += timeDiffer;
    
    [self seekWithProgress:playTimeSec / totalTimeSec];
    
}

#pragma mark - Setter、Getter
- (void)setRate:(float)rate {
    [self.player setRate:rate];
}

- (float)rate {
    return self.player.rate;
}

- (void)setMuted:(BOOL)muted {
    self.player.muted = muted;
}

- (BOOL)muted {
    return self.player.muted;
}

- (void)setVolume:(float)volume {
    if (volume < 0 || volume > 1) {
        return;
    }
    if (volume > 0) {
        [self setMuted:NO];
    }
    
    self.player.volume = volume;
}

- (float)volume {
    return self.player.volume;
}


#pragma mark - Setter、Getter(数据/事件)
/**
 当前音频资源总时长
 
 @return 总时长
 */
-(NSTimeInterval)totalTime {
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if (isnan(totalTimeSec)) {
        return 0;
    }
    return totalTimeSec;
}

/**
 当前音频资源总时长(格式化后)
 
 @return 总时长 01:02
 */
- (NSString *)totalTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.totalTime / 60, (int)self.totalTime % 60];
}

/**
 当前音频资源播放时长
 
 @return 播放时长
 */
- (NSTimeInterval)currentTime {
    CMTime playTime = self.player.currentItem.currentTime;
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    if (isnan(playTimeSec)) {
        return 0;
    }
    return playTimeSec;
}
/**
 当前音频资源播放时长(格式化后)
 
 @return 播放时长
 */
- (NSString *)currentTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.currentTime / 60, (int)self.currentTime % 60];
}

/**
 当前播放进度
 
 @return 播放进度
 */
- (float)progress {
    if (self.totalTime == 0) {
        return 0;
    }
    return self.currentTime / self.totalTime;
}

/**
 资源加载进度
 
 @return 加载进度
 */
- (float)loadDataProgress {
    
    if (self.totalTime == 0) {
        return 0;
    }
    
    CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    
    CMTime loadTime = CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    
    return loadTimeSec / self.totalTime;
    
}

/**
 状态变更, 事件触发
 
 @param state 状态
 */
- (void)setState:(JCRemotePlayerState)state {
    _state = state;
    
    // 如果需要告知外界相关的事件
    // block
    // 代理
    // 发通知
}

#pragma mark - Noti
/**
 播放完成
 */
- (void)playEnd {
    NSLog(@"播放完成");
    self.state = JCRemotePlayerStateStopped;
}

/**
 被打断
 */
- (void)playInterupt {
    // 来电话, 资源加载跟不上
    NSLog(@"播放被打断");
    self.state = JCRemotePlayerStatePause;
}
 
#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"资源准备好了, 这时候播放就没有问题");
            [self resume];
        }else {
            NSLog(@"状态未知");
            self.state = JCRemotePlayerStateFailed;
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        BOOL ptk = [change[NSKeyValueChangeNewKey] boolValue];
        if (ptk) {
            NSLog(@"当前的资源, 准备的已经足够播放了");
            //
            // 用户的手动暂停的优先级最高
            if (!_isUserPause) {
                [self resume];
            }else {
                
            }
            
        }else {
            NSLog(@"资源还不够, 正在加载过程当中");
            self.state = JCRemotePlayerStateLoading;
        }
        
        
    }
}

/**
 移除监听者, 通知
 */
- (void)removeObserver {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
