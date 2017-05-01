//
//  JCAudioFileTool.h
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/5/1.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCAudioFileTool : NSObject
/**
 *  缓存全路径
 */
+ (NSString *)cachePathWithURL: (NSURL *)url;

/**
 *  临时缓存路径
 */
+ (NSString *)tmpPathWithURL: (NSURL *)url;

/**
 *  是否存在当前路径
 */
+ (BOOL)isCacheFileExists: (NSURL *)url;
+ (BOOL)isTmpFileExists: (NSURL *)url;

/**
 *  url 的 contentType
 */
+ (NSString *)contentTypeWithURL: (NSURL *)url;


/**
 *  当前路径的文件大小, 找不到路径就是0
 */
+ (long long)cacheFileSizeWithURL: (NSURL *)url;
+ (long long)tmpFileSizeWithURL: (NSURL *)url;

/**
 *  移除临时文件
 */
+ (void)removeTmpFileWithURL: (NSURL *)url;

/**
 *  将当前临时路径的文件移到正式路径中
 */
+ (void)moveTmpPathToCachePath: (NSURL *)url;
@end
