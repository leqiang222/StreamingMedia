//
//  JCAudioDownLoader.h
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/5/1.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import <Foundation/Foundation.h>
@class JCAudioDownLoader;

@protocol JCAudioDownLoaderDelegate <NSObject>

/**
 *  音频正在下载中...
 */
- (void)audioDownLoaderIsLoading:(JCAudioDownLoader *)audioDownLoader;

@end


@interface JCAudioDownLoader : NSObject
/** 文件总大小 */
@property (nonatomic, assign) long long totalSize;
/** 已下载的数据大小 */
@property (nonatomic, assign) long long loadedSize;
@property (nonatomic, assign) long long offset;
@property (nonatomic, strong) NSString *mimeType;

@property (nonatomic, weak) id<JCAudioDownLoaderDelegate> delegate;

/**
 根据远程地址下载 音频
 
 @param url    远程地址
 @param offset <#offset description#>
 */
- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset;


@end
