//
//  JCRootViewController.m
//  00-仿微信小视频
//
//  Created by leqiang222 on 2017/4/10.
//  Copyright © 2017年 静持大师. All rights reserved.
//

#import "JCRootViewController.h"
#import "JCVideoController.h" // 00 视频采集 + 硬编码
#import "JCAVPlayerController.h" // 01 AVPlayer简单使用
#import "JCAudioViewController.h"

@interface JCRootViewController ()
/** <#Description#> */
@property (nonatomic, strong) NSArray *listArray;
@end

@implementation JCRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"选项入口";
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const kCellId = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = self.listArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0: {
            JCVideoController *vc = [[JCVideoController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 1: {
            JCAVPlayerController *avPlay = [[JCAVPlayerController alloc] init];
            [self.navigationController pushViewController:avPlay animated:YES];
        }
            break;
            
        case 2: {
            JCAudioViewController *audio = [[JCAudioViewController alloc] init];
            [self.navigationController pushViewController:audio animated:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Lazy
- (NSArray *)listArray {
    if (!_listArray) {
        _listArray = @[@"视频采集->硬编码->存储->硬解码->播放",
                       @"AVPlayer简单使用",
                       @"远程播放缓存音频"];

    }
    return _listArray;
}
@end
