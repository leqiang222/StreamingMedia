//
//  JCVideoCapture.h
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/3/29.
//  Copyright © 2017年 静持大师. All rights reserved.
//

/**
 *  采集视频
 */

#import <UIKit/UIKit.h>

@interface JCVideoCapture : NSObject

+ (instancetype)shareInstance;


/**
 采集数据

 @param preView 预览图层
 */
- (void)startCapture:(UIView *)preView;

- (void)stopCapture;

@end
