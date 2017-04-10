//
//  JCVideoController.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/4/10.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "JCVideoController.h"
#import "JCVideoCapture.h"

const char pStartCode[] = "\x00\x00\x00\x01";

@interface JCVideoController () {
    long maxInputSize;
    long inputSize;
    uint8_t *inputBuffer;
    
    long packetSize;
    uint8_t *packetBuffer;
}
@property (weak, nonatomic) IBOutlet UIView *videoView;
/** <#Description#> */
@property (nonatomic, strong) CADisplayLink *link;
/** <#Description#> */
@property (nonatomic, strong) NSInputStream *stream;
/** <#Description#> */
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation JCVideoController

- (void)viewDidLoad {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"读数据" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonDidClick)];
}


#pragma mark - Action
- (IBAction)caiji:(id)sender {
    NSLog(@"__开始采集__");
    
    JCVideoCapture *capture = [JCVideoCapture shareInstance];
    [capture startCapture:self.videoView];
}

- (IBAction)bucaiji:(id)sender {
    NSLog(@"__停止采集__");
    
    JCVideoCapture *capture = [JCVideoCapture shareInstance];
    [capture stopCapture];
}

- (void)rightBarButtonDidClick {
    //
    maxInputSize = 1280 * 720;
    inputSize = 0;
    inputBuffer = malloc(maxInputSize); // 申请内存
    
    [self.stream open];
    
    // 开始读取数据
    [self.link setPaused:NO];
}

#pragma mark - 读取数据
- (void)updateFram {
    dispatch_sync(self.queue, ^{
        // 读取数据
        [self readPacket];
        
        // 判断数据类型
        if (packetSize == 0 && packetBuffer == NULL) {
            [self.link setPaused:YES];
            NSLog(@"__数据已读完__");
            
            return ;
        }
        
        // 解码
        NSLog(@"__读取到数据__");
        uint32_t NALSize = (uint32_t)(packetSize - 4);
        uint32_t *pNAL = (uint32_t)packetBuffer;
        CFSwapInt32HostToBig(NALSize);
        
        
    });
}

- (void)readPacket {
    // 第二次读取的时候保证之前的数据清除掉
    if (packetSize || packetBuffer) {
        packetSize = 0;
        
        free(packetBuffer);
        packetBuffer = nil;
    }
    
    // 读取数据
    if (inputSize < maxInputSize && self.stream.hasBytesAvailable) {
        inputSize += [self.stream read:inputBuffer + inputSize maxLength:maxInputSize - inputSize];
    }
    
    // 获取解码想要的数据
    // inputSize -= 1000;
    //
    if (memcmp(inputBuffer, pStartCode, 4) == 0) { // 函数正常
        uint8_t *pStart = inputBuffer + 4;
        uint8_t *pEnd = pStart + inputSize - 4;
        
        while (pStart != pEnd) {
            if (memcmp(pStart - 3, pStartCode, 4)) {
                // 获取下一个00 00 00 01
                packetSize = pStart - 3 - inputBuffer;
                
                // 从inputBuffer拷贝数据到packetBuffer去
                packetBuffer =malloc(packetSize);
                memcpy(packetBuffer, inputBuffer, packetSize);
                
                // 将数据移动到最前方
                memmove(inputBuffer, inputBuffer + packetSize, inputSize - packetSize);
                
                // 改变inputSize大小
                inputSize -= packetSize;
                
            }else {
                pStart += 1;
            }
        }
    }
}

@end


/*
 - (void)test {
 // 1.
 CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFram)];
 self.link = link;
 link.frameInterval = 2;
 [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
 [link setPaused:YES];
 
 // 2.
 self.stream = [NSInputStream inputStreamWithFileAtPath:@"/Users/admin/Desktop/123.h264"];
 
 //
 self.queue = dispatch_get_global_queue(0, 0);
 }

 */
