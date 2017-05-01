//  NSLog(@"/remoteAudio/-------- <#描述#> --------/remoteAudio/");
//  JCRemotePlayer.h
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/5/1.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  播放器的状态
 */
typedef NS_ENUM(NSInteger, JCRemotePlayerState) {
    JCRemotePlayerStateUnknown   = 0, // 未知(比如都没有开始播放音乐)
    JCRemotePlayerStateLoading   = 1, // 正在加载()
    JCRemotePlayerStatePlaying   = 2, // 正在播放
    JCRemotePlayerStateStopped   = 3, // 停止
    JCRemotePlayerStatePause     = 4, // 暂停
    JCRemotePlayerStateFailed    = 5 // 失败(比如没有网络缓存失败, 地址找不到)
};

@interface JCRemotePlayer : NSObject

#pragma mark - 属性
/** 速率 */
@property (nonatomic, assign) float rate;
/** 声音 */
@property (nonatomic, assign) float volume;
/** 静音 */
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign, readonly) double duration;
@property (nonatomic, assign, readonly) double currentTime;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, assign, readonly) float loadProgress;
@property (nonatomic, assign, readonly) JCRemotePlayerState state;

@property (nonatomic, copy) void(^stateChange)(JCRemotePlayerState state);
@property (nonatomic, copy) void(^playEndBlock)();

#pragma mark - 方法
/**
 根据URL地址进行播放音频
 
 @param url url
 */
- (void)playWithURL: (NSURL *)url;

/**
 暂停当前音频
 */
- (void)pause;

/**
 继续播放
 */
- (void)resume;

/**
 停止播放
 */
- (void)stop;

/**
 快速播放到某个时间点
 
 @param time 时间
 */
- (void)seekWithTime: (NSTimeInterval)time;

/**
 根据进度播放
 
 */
//- (void)seekWithProgress: (float)progress;


@end
