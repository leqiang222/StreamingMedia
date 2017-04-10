//
//  JCVideoCapture.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/3/29.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "JCVideoCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "JCH264Encoder.h"

static JCVideoCapture *instance = nil;

@interface JCVideoCapture () <AVCaptureVideoDataOutputSampleBufferDelegate>
/** <#Description#> */
@property (nonatomic, strong) UIView *preView;
/** <#Description#> */
@property (nonatomic, strong) JCH264Encoder *h264Encoder;
/**< 捕捉会话 */
@property (nonatomic, strong) AVCaptureSession *captureSession;
/** 设备输出对象，用于获得输出数据 */
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureMovieFileOutput;
/**< 相机拍摄预览图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@end

@implementation JCVideoCapture

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JCVideoCapture alloc] init];
    });

    return instance;
}

- (void)startCapture:(UIView *)preView {
    self.h264Encoder = [[JCH264Encoder alloc] init];
    [self.h264Encoder prepareEncodeWithWidth:1280 height:720];
    
    // 1.创建 session 和设置输入
    NSError *error = nil;
    BOOL isInput = [self setupSessionInputs:&error];
    
    if (!isInput) {
        NSLog(@"error: %@", error);
        return;
    }
    
    self.preView = preView;

    // 2.设置视频输出
    [self setupFileOutput];
    
    // 3. 设置预览图层
    [self setupPreviewLayer];
}

- (void)stopCapture {
    [self.captureVideoPreviewLayer removeFromSuperlayer];
    [self.captureSession stopRunning];
}

- (BOOL)setupSessionInputs:(NSError **)error {
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.captureSession = session;
    if ([session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    // 1.添加视频输入 
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *vedioDevice = nil;
    for ( AVCaptureDevice *device in devices )
        if (device.position == AVCaptureDevicePositionFront) {
            vedioDevice = device;
        }
    
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:vedioDevice error:error];
    
    if (!videoInput) {
        NSLog(@"__输入设备为 nil__");
    }
    
    if (![self.captureSession canAddInput:videoInput]) {
        NSLog(@"__摄像头无法使用__");
        return NO;
    }
    
    [self.captureSession addInput:videoInput];
    
    return YES;
}

- (void)setupFileOutput {
    // 初始化设备输出对象，用于获得输出数据
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc]init];
    self.captureMovieFileOutput = output;
    output.alwaysDiscardsLateVideoFrames = YES; // 实时输出
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    
    // 设置录制模式
    // 默认是横屏
    AVCaptureConnection *captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoStabilizationSupported]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
    
    // 将设备输出添加到会话中
    if ([self.captureSession canAddOutput:output]) {
        [self.captureSession addOutput:output];
    } 
}

/**
 *
 */
- (void)setupPreviewLayer {
    // 创建视频预览层，用于实时展示摄像头状态
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    self.captureVideoPreviewLayer = previewLayer;
    previewLayer.frame = self.preView.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // 填充模式
    
    [self.preView.layer insertSublayer:previewLayer atIndex:0];
    self.preView.layer.masksToBounds = YES;
    
    //
    [self.captureSession startRunning];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

/**
 *  采集到帧(sampleBuffer)
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
        [self.h264Encoder encodeFram:sampleBuffer];
//    NSLog(@"__采集了帧__");
}

/**
 *  出现了丢帧
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"__出现了丢帧__");
}


@end
