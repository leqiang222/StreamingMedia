//
//  NSURL+Audio.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/5/1.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "NSURL+Audio.h"

@implementation NSURL (Audio)

- (NSURL *)kl_streamingURL {
    
    NSURLComponents *commpents = [NSURLComponents componentsWithString:self.absoluteString];
    [commpents setScheme:@"streaming"];
    
    return [commpents URL];
    
}

- (NSURL *)kl_httpURL {
    NSURLComponents *commpents = [NSURLComponents componentsWithString:self.absoluteString];
    [commpents setScheme:@"http"];
    
    return [commpents URL];
}



@end
