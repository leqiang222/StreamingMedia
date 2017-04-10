//
//  JCH264Encoder.h
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/3/29.
//  Copyright © 2017年 静持大师. All rights reserved.
//

/**
 *  视频编码
 */

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface JCH264Encoder : NSObject

/**
 *  准备编码
 */
- (void)prepareEncodeWithWidth:(int)width height:(int)height;

/**
 *  开始编码
 */
- (void)encodeFram:(CMSampleBufferRef)sampleBufferRef;

@end
