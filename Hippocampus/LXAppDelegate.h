//
//  LXAppDelegate.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCPermissionViewController.h"

@interface LXAppDelegate : UIResponder <UIApplicationDelegate>
{
    BOOL active;
}

@property (strong, nonatomic) UIWindow *window;

- (void) setRootStoryboard:(NSString*)name;
- (void) setBadgeIcon;
- (void) getPushNotificationPermission;

@end
