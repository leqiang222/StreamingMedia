//
//  JCH264Encoder.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/3/29.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "JCH264Encoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface JCH264Encoder ()
/** <#Description#> */
@property (nonatomic, assign) VTCompressionSessionRef compressionSession;
/** <#Description#> */
@property (nonatomic, assign) int frameIndex;
/** <#Description#> */
@property (nonatomic, strong) NSFileHandle *fileHandle;
@end

@implementation JCH264Encoder

#pragma mark - 编码
- (void)prepareEncodeWithWidth:(int)width height:(int)height {
    // -1.
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject stringByAppendingPathComponent:@"123.h264"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    
    
    // 0.默认0帧
    self.frameIndex = 0;
    
    //-----------------------------------------------------------------------------
    // 1.创建 VTCompressionSessionRef
    // param CFAllocatorRef: 用于CoreFoundation分配内存的模式，传NULL表示默认
    // param width: 编码出来的宽度
    // param height: 编码出来的高度
    // param CMVideoCodecType: 编码标准
    // param CFDictionaryRef:
    // param VTCompressionOutputCallback: 获取编码后的回调函数
    // param outputCallbackRefCon: 传 self
    // param VTCompressionSessionRef: 可以传递到回调函数中参数
    VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, jc_compressionOutputCallback, (__bridge void * _Nullable)(self), &_compressionSession);
    
    //------------------------------------------------------------------------------

    // 2.设置属性
    // 2.1 设置实时输出
    // param kVTCompressionPropertyKey_RealTime: 实时输出
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    // 2.2 设置24帧率
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)(@24));
    
    // 2.3 设置比特率(码率)
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nonnull)(@1500000));// bit
    // 1秒钟1500000b
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef _Nonnull)(@[@(1500000/8), @1])); // byte, 所以要除8
    
    // 2.4 设置GOP的大小
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)(@20));
    
    
    //------------------------------------------------------------------------------
    // 3.准备编码
    VTCompressionSessionPrepareToEncodeFrames(_compressionSession);
}

- (void)encodeFram:(CMSampleBufferRef)sampleBufferRef {
    // 1.将CMSampleBufferRef转成CVImageBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    
    CMTime pts = CMTimeMake(self.frameIndex, 24); // 24表示帧率
    VTEncodeInfoFlags infoFlagsOut;
    
    // 2.开始编码
    // param2 presentationTimeStamp: PTS(presentationTimeStamp)
    // param3 duration:
    // param5 frameProperties:
    // param6 : 回调函数第二个参数
    // param7: 回调函数第四个参数
    VTCompressionSessionEncodeFrame(_compressionSession, imageBuffer, pts, kCMTimeInvalid, NULL, (__bridge void * _Nullable)(self), &infoFlagsOut);
    
    NSLog(@"------开始编码一帧图片-------");
}

#pragma mark - Private (编码回调函数)
void (jc_compressionOutputCallback)(void * CM_NULLABLE outputCallbackRefCon,
                                     void * CM_NULLABLE sourceFrameRefCon,
                                     OSStatus status,
                                     VTEncodeInfoFlags infoFlags,
                                     CM_NULLABLE CMSampleBufferRef sampleBuffer) {
    NSLog(@"------编码出了一帧图片-------");
    
    JCH264Encoder *H264Encoder = (__bridge JCH264Encoder *)(outputCallbackRefCon);
    
    //------------------------------------------------------------------------------
    // 1.判断是否是关键帧
    CFArrayRef arrayRef = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(arrayRef, 0);
    BOOL isKeyFram = CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    
    //------------------------------------------------------------------------------
    // 2.如果是关键帧，获取SPS/PPS数据，并写入数据
    if (isKeyFram) {
        // 2.1 格式化描述, 从CMSampleBufferRef中获取CMFormatDescriptionRef
        CMFormatDescriptionRef formatDes = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 2.2 获取SPS信息
        const uint8_t *spsOut;
        size_t spsSize, spsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDes, 0, &spsOut, &spsSize, &spsCount, NULL);
        
        // 2.3 获取 PPS
        const uint8_t *ppsOut;
        size_t ppsSize, ppsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDes, 1, &ppsOut, &ppsSize, &ppsCount, NULL);
        
        // 2.4将 SPS和 PPS 转成NSData
        NSData *spsData = [NSData dataWithBytes:spsOut length:spsSize];
        NSData *ppsData = [NSData dataWithBytes:ppsOut length:ppsSize];
        
        // 2.5 写入文件(NALU单元: 0x00 00 00 01)
        [H264Encoder writeData:spsData];
        [H264Encoder writeData:ppsData];
    }
    
    //------------------------------------------------------------------------------
    // 3.写入数据
    // 3.1 获取CMBlockBufferRef
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    // 3.2 从blockBuffer中获取起始位置的内存地址
    size_t totalLength = 0;
    char *dataPointer; // 起始位置
    CMBlockBufferGetDataPointer(blockBuffer, 0, 0, &totalLength, &dataPointer);
    
    // 3.3 一帧的图像可能需要写入多个 NAUL 单元 -> Slice切换
    static const int H264HeaderLength = 4; // 先读取前四位
    size_t bufferOffset = 0;
    
    while (bufferOffset < totalLength - H264HeaderLength) {
        // 3.4 从起始位置拷贝H264HeaderLength长度位置，计算NALULength
        int NALULength = 0;
        memcpy(&NALULength, dataPointer, H264HeaderLength);
        
        // H264编码的数据是大端模式(字节序)
        NALULength = CFSwapInt32BigToHost(NALULength);
        
        //3.5 从dataPointer开始，根据长度创建 NSData
        NSData *data = [NSData dataWithBytes:dataPointer + bufferOffset + H264HeaderLength length:NALULength];
        
        // 3.6 写入文件
        [H264Encoder writeData:data];
        
        // 3.7 从新设置bufferOffset
        bufferOffset += NALULength + H264HeaderLength;
    }
}

#pragma mark - Private
/**
 *  写入数据
 */
- (void)writeData:(NSData *)data {
    // 1. 获取 startCode
    const char bytes[] = "\x00\x00\x00\x01";
    
    // 2.获取headerData
    NSData *headerData = [NSData dataWithBytes:bytes length:sizeof(bytes) - 1];

    // 3.写入文件
    [self.fileHandle writeData:headerData];
    [self.fileHandle writeData:data];
}


@end
