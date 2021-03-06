//
//  JCAudioViewController.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/5/1.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "JCAudioViewController.h"
#import "JCRemotePlayer.h"
#import "NSURL+Audio.h"

@interface JCAudioViewController ()
@property (weak, nonatomic) IBOutlet UIButton *muteBtn;
@property (weak, nonatomic) IBOutlet UILabel *costTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimelabel;
@property (weak, nonatomic) IBOutlet UISlider *playProgressSlider;

@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@property (weak, nonatomic) IBOutlet UIProgressView *loadProgressProgress;

@property (nonatomic, weak) NSTimer *timer;
@end

@implementation JCAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - Action(Button)
/**
 *  播放
 */
- (IBAction)play:(id)sender {
    NSLog(@"/remoteAudio/-------- 开始播放 --------/remoteAudio/");
    
//    NSString *path = @"http://audio.xmcdn.com/group23/M06/5C/70/wKgJL1g0DVahoMhrAMJMkvfN17c025.m4a";
    NSString *path = @"http://120.25.226.186:32812/resources/videos/minion_01.mp4";
    NSURL *url = [NSURL URLWithString:path];
    [[JCRemotePlayer shareInstance] playWithURL:url isCache:YES];
    
//    [self.player setStateChange:^(JCRemotePlayerState state) { // 播放状态改变
//        NSLog(@"/remoteAudio/-------- 播放状态状态: %zd --------/remoteAudio/", state);
//    }];
    
//    [self.player setPlayEndBlock:^{ // 播放完成
//        NSLog(@"/remoteAudio/-------- 播放完成 --------/remoteAudio/");
//    }];
}

/**
 *  暂停
 */
- (IBAction)pause:(UIButton *)sender {
    [[JCRemotePlayer shareInstance] pause];
}

/**
 *  继续
 */
- (IBAction)resume:(UIButton *)sender {
    [[JCRemotePlayer shareInstance] resume];
}

/**
 *  快进或快退
 */
- (IBAction)fastOrSlow:(UIButton *)sender {
    [[JCRemotePlayer shareInstance] seekWithTimeDiffer:20];
}

/**
 *  倍数
 */
- (IBAction)rate:(UIButton *)sender {
    [[JCRemotePlayer shareInstance] setRate:2.0];
}

/**
 *  静音
 */
- (IBAction)mute:(UIButton *)sender {
    sender.selected = !sender.selected;
    [[JCRemotePlayer shareInstance] setMuted:sender.selected];
}

#pragma mark - Action(Slider)
/**
 *  播放进度
 */
- (IBAction)progress:(UISlider *)sender {
     [[JCRemotePlayer shareInstance] seekWithProgress:sender.value];
}


/**
 *  调节音量大小
 */
- (IBAction)volume:(UISlider *)sender {
     [[JCRemotePlayer shareInstance] setVolume:sender.value];
}

- (void)update {
    
    //    NSLog(@"--%zd", [XMGRemotePlayer shareInstance].state);
    // 68
    // 01:08
    // 设计数据模型的
    // 弱业务逻辑存放位置的问题
//    self.playTimeLabel.text =  [XMGRemotePlayer shareInstance].currentTimeFormat;
//    self.totalTimeLabel.text = [XMGRemotePlayer shareInstance].totalTimeFormat;
//    
//    self.playSlider.value = [XMGRemotePlayer shareInstance].progress;
//    
//    self.volumeSlider.value = [XMGRemotePlayer shareInstance].volume;
//    
//    self.loadPV.progress = [XMGRemotePlayer shareInstance].loadDataProgress;
//    
//    self.mutedBtn.selected = [XMGRemotePlayer shareInstance].muted;
}


#pragma mark - Lazy
- (NSTimer *)timer {
    if (!_timer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(update) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        _timer = timer;
    }
    
    return _timer;
}


//- (JCRemotePlayer *)player {
//    if (!_player) {
//        _player = [[JCRemotePlayer alloc] init];
//    }
//    return _player;
//}


@end
