//
//  LXAppDelegate.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCPermissionViewController.h"
#import <Pusher/Pusher.h>

@interface LXAppDelegate : UIResponder <UIApplicationDelegate, PTPusherDelegate>
{
    BOOL active;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) PTPusher* client;

- (void) setRootStoryboard:(NSString*)name;
- (void) setBadgeIcon;
- (void) getPushNotificationPermission;

@end
