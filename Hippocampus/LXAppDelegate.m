//
//  LXAppDelegate.m
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXAppDelegate.h"
#import <AudioToolbox/AudioServices.h>
#import "NSString+SHAEncryption.h"

@implementation LXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //flush images from SGImageCache
    [SGImageCache flushImagesOlderThan:([[[NSDate alloc] init] timeIntervalSince1970]-24*60*60)];
    
    //Default appearance
    [self.window setTintColor:[UIColor mainColor]];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont titleFontWithSize:13.0f]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont titleFontWithSize:14.0f]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor mainColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont titleFontWithSize:16.0f], NSForegroundColorAttributeName : [UIColor SHFontDarkGray]}];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName:[UIFont titleFontWithSize:14.0f]}];
    
    // Override point for customization after application launch.
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [[LXSession thisSession] setVariables];
    
    if ([self shouldPresentIntroductionViews]) {
        [self setRootStoryboard:@"Login"];
    } else {
        [self setRootStoryboard:@"Seahorse"];
    }
    [self loadAddressBook];
    
    return YES;
}

- (void) refreshObjects
{
    [[LXObjectManager defaultManager] refreshObjectTypes:@"buckets" withAboveUpdatedAt:nil
                                                 success:^(id responseObject){
                                                 }
                                                 failure:^(NSError* error){
                                                 }
     ];
    [[LXObjectManager defaultManager] refreshObjectTypes:@"items" withAboveUpdatedAt:nil
                                                 success:^(id responseObject){
                                                 }
                                                 failure:^(NSError* error){
                                                 }
     ];
}

- (BOOL) shouldPresentIntroductionViews
{
    return ![[LXSession thisSession] user];
}

- (void) setRootStoryboard:(NSString*)name
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:name bundle:[NSBundle mainBundle]];
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
    if (([name isEqualToString:@"Seahorse"]) && [[LXSession thisSession] user]) {
        //[[[LXSession thisSession] user] performSelector:@selector(updateTimeZone) withObject:nil afterDelay:10];
        [[[LXSession thisSession] user] updateTimeZone];
        [self refreshObjects];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    
    active = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
        }];
        [LXObjectManager saveToDisk];
        [[UIApplication sharedApplication] endBackgroundTask:bgt];
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self setBadgeIcon];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"appAwake" object:nil];
    
    if ([[LXSession thisSession] user]) {
        [[LXObjectManager defaultManager] runQueries];
        //[[LXObjectManager defaultManager] performSelector:@selector(runQueries) withObject:nil afterDelay:1];
    }
    
    [self handleAppLaunch];
    
    if ([[LXSession thisSession] locationPermissionDetermined]) {
        [[LXSession thisSession] startLocationUpdates];
        //[[LXSession thisSession] performSelector:@selector(startLocationUpdates) withObject:nil afterDelay:2];
    }
    
    active = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}


# pragma mark - Background Fetch

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([[LXSession thisSession] user]) {
        [[[LXSession thisSession] user] updateTimeZone];
    }
}





# pragma mark - Notifications

- (void) getPushNotificationPermission
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:@"doneAskingForPushNotificationPermission"];
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [self registerDeviceToken:deviceToken];
}

- (void) registerDeviceToken:(NSData*)deviceToken
{
    [[LXServer shared] updateDeviceToken:deviceToken
                                 success:^(id responseObject) {
                                     NSLog(@"My token is: %@", deviceToken);
                                 } failure:^(NSError *error){
                                     NSLog(@"Didn't successfully submit device token: %@", deviceToken);
                                 }
    ];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (active) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        return;
    }
    //[userInfo objectForKey:@"bucket_id"] && [[userInfo objectForKey:@"bucket_id"] respondsToSelector:@selector(intValue)]
}


- (void) setBadgeIcon
{
    if ([LXSession areNotificationsEnabled]) {
        if ([[[[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"] objectForKey:@"Recent"] firstObject] isAllNotesBucket]) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[[[[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"] objectForKey:@"Recent"] firstObject] objectForKey:@"items_count"] integerValue]];
        } else {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }
    }
}


# pragma mark other actions

- (void) handleAppLaunch
{
    if (![[LXSession thisSession] user]) {
        return;
    }
    //EMAIL
    //[self permissionsDelegate:@"email"];
    
    if ([LXSession areNotificationsEnabled]) {
        //PUSH NOTIFICATIONS ENABLED
        [self getPushNotificationPermission];
    }
}



# pragma mark - contacts

- (void) loadAddressBook
{
    if ([[LXAddressBook thisBook] permissionGranted]) {
        [[LXAddressBook thisBook] obtainContactList:^(BOOL success) {
            NSLog(@"loadAddressbook completed");
        }];
    }
}







//- (void) permissionsDelegate:(NSString*)type
//{
//    if ([type isEqualToString:@"email"]) {
//        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
//        mc.mailComposeDelegate = self;
//        [mc setSubject:[NSString stringWithFormat:@"My Token: (%@==%@", [NSString userAuthToken], [[[LXSession thisSession] user] ID]]];
//        [mc setMessageBody:@"Hit 'Send' in the top right corner to verify this email address! (and don't delete/change the subject of this email)\n\nVerify me! Cheers," isHTML:NO];
//        [mc setToRecipients:@[@"thought@hppcmps.com"]];
//        [self.window.rootViewController presentViewController:mc animated:YES completion:nil];
//    }
//}
//
//- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
//{
//    switch (result)
//    {
//        case MFMailComposeResultCancelled:
//            NSLog(@"Mail cancelled");
//            break;
//        case MFMailComposeResultSaved:
//            NSLog(@"Mail saved");
//            break;
//        case MFMailComposeResultSent:
//            NSLog(@"Mail sent");
//            break;
//        case MFMailComposeResultFailed:
//            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
//            break;
//        default:
//            break;
//    }
//    [controller dismissViewControllerAnimated:YES completion:NULL];
//}
//
//- (void) permissionsDelegate
//{
//}



@end
