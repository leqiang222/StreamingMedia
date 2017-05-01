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

@interface JCRemotePlayer () {
    BOOL _isUserPause; // 是否是用户暂停播放的
}
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) JCResourceLoader *resourceLoader;
@end

@implementation JCRemotePlayer

#pragma mark - Public
- (void)playWithURL: (NSURL *)url {
    if ([_url isEqual:url]) {
        if (self.state == JCRemotePlayerStatePlaying || self.state == JCRemotePlayerStateLoading) {
            return;
        }
        
        if (self.state == JCRemotePlayerStatePause) {
            [self resume];
            return;
        }
    }

    _url = url;
    
    // 系统已经帮我们封装了三个步骤 [AVPlayer playerWithURL:url]
    // 包括: 1. 资源的请求; 2. 资源的组织 AVPlayerItem; 3. 资源的播放
    if (self.player.currentItem) {
        // 移除之前资源的监听
        [self clearObserver:self.player.currentItem];
    }
    
    // 
    AVURLAsset *asset = [AVURLAsset assetWithURL:[url kl_streamingURL]];
    [asset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    
    // 监听资源的组织者, 有没有组织好数据
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听播放状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playIntrupt) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    // 开始播放
    self.player = [AVPlayer playerWithPlayerItem:item];
}

- (void)pause {
    [self.player pause];
    if (self.player) {
        _isUserPause = YES;
        self.state = JCRemotePlayerStatePause;
    }
}

- (void)resume {
    [self.player play];
    if (self.player && self.player.currentItem.playbackLikelyToKeepUp) {
        _isUserPause = NO;
        self.state = JCRemotePlayerStatePlaying;
    }
}

- (void)stop {
    [self.player pause];
    [self clearObserver:self.player.currentItem];
    self.player = nil;
    self.state = JCRemotePlayerStateStopped;
}

- (void)seekWithTime: (NSTimeInterval)time{
    
    // CMTime 影片时间
    // 影片时间 -> 秒
    // 秒 -> 影片时间
    
    // 1. 获取当前的时间点(秒)
    double currentTime = self.currentTime + time;
    double totalTime = self.duration;
    
    [self setProgress:currentTime / totalTime];
}


#pragma mark - Setter、Getter
- (void)setRate:(float)rate {
    self.player.rate = rate;
}

- (float)rate {
    return self.player.rate;
}

- (void)setVolume:(float)volume {
    if (volume > 0) {
        [self setMute:NO];
    }
    self.player.volume = volume;
}

- (float)volume {
    return self.player.volume;
}

- (void)setMute:(BOOL)mute {
    self.player.muted = mute;
}

- (BOOL)mute {
    return self.player.isMuted;
}

- (double)duration {
    double time = CMTimeGetSeconds(self.player.currentItem.duration);
    if (isnan(time)) {
        return 0;
    }
    return time;
}

- (double)currentTime {
    
    double time = CMTimeGetSeconds(self.player.currentItem.currentTime);
    
    if (isnan(time)) {
        return 0;
    }
    return time;
}

- (float)progress {
    
    if (self.duration == 0) {
        return 0;
    }
    return self.currentTime / self.duration;
}

- (void)setProgress:(float)progress {
    // 0.0 - 1.0
    // 1. 计算总时间 (秒) * progress
    
    double totalTime = self.duration;
    double currentTimeSec = totalTime * progress;
    CMTime playTime = CMTimeMakeWithSeconds(currentTimeSec, NSEC_PER_SEC);
    
    [self.player seekToTime:playTime completionHandler:^(BOOL finished) {
        
        if (finished) {
            NSLog(@"确认加载这个时间节点的数据");
        }else {
            NSLog(@"取消加载这个时间节点的播放数据");
        }
    }];
}

- (void)setState:(JCRemotePlayerState)state {
    _state = state;
    if (self.stateChange) {
        self.stateChange(state);
    }
}


-(float)loadProgress {
    CMTimeRange range = [self.player.currentItem.loadedTimeRanges.lastObject CMTimeRangeValue];
    CMTime loadTime = CMTimeAdd(range.start, range.duration);
    double loadTimeSec = CMTimeGetSeconds(loadTime);
    
    if (self.duration == 0) {
        return 0;
    }
    
    return loadTimeSec / self.duration;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                NSLog(@"准备完毕, 开始播放");
                [self resume];
                break;
            }
            case AVPlayerItemStatusFailed: {
                NSLog(@"数据准备失败, 无法播放");
                self.state = JCRemotePlayerStateFailed;
                break;
            }
                
            default: {
                NSLog(@"未知");
                self.state = JCRemotePlayerStateUnknown;
                break;
            }
        }
        
    }
    
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        // 代表, 是否加载的可以进行播放了
        BOOL playbackLikelyToKeepUp = [change[NSKeyValueChangeNewKey] boolValue];
        if (playbackLikelyToKeepUp) {
            NSLog(@"数据加载的足够播放了");
            
            
            // 能调用, 播放
            // 手动暂停, 优先级 > 自动播放
            if (!_isUserPause) {
                [self resume];
            }
            
        }else {
            NSLog(@"数据不够播放");
            self.state = JCRemotePlayerStateLoading;
        }
    }
}

#pragma mark - NSNotification
/**
 *  播放结束
 */
- (void)playEnd {
    self.state = JCRemotePlayerStateStopped;
    if (self.playEndBlock) {
        self.playEndBlock();
    }
}

/**
 *  播放打断
 */
- (void)playIntrupt {
    NSLog(@"/remoteAudio/-------- 播放被打断 --------/remoteAudio/");
    self.state = JCRemotePlayerStatePause;
}

#pragma mark - Other
- (void)clearObserver: (AVPlayerItem *)item {
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

- (void)dealloc {
    [self clearObserver:self.player.currentItem];
    
}

#pragma mark - Lazy
- (JCResourceLoader *)resourceLoader {
    if (!_resourceLoader) {
        _resourceLoader = [[JCResourceLoader alloc] init];
    }
    return _resourceLoader;
}
@end
