//
//  AppDelegate.m
//  QQMusicPlayer
//
//  Created by mac on 15/12/30.
//  Copyright (c) 2015年 WXHL. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryErr];
    
    [[AVAudioSession sharedInstance] setActive:YES error:&activationErr];
    
    //缺少这一句后台不能自动切换歌曲
    [application beginReceivingRemoteControlEvents];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    
    __block    UIBackgroundTaskIdentifier bgTask;
    
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid){
            bgTask = UIBackgroundTaskInvalid;
        }
        });
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid){
            bgTask = UIBackgroundTaskInvalid;
        }
        });
    });
}

//响应远程音乐播放控制消息
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedEventSubtype" object:@"AppDelegate" userInfo:@{@"receivedEventSubtype":@(receivedEvent.subtype)}];
        
    }
}

@end
