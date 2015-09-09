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
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:[[UIFont titleFont] fontName] size:13.0f]} forState:UIControlStateNormal];
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
        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[[LXSession thisSession] user] updateTimeZone];
        //});
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
    
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([[LXSession thisSession] user]) {
            [[LXObjectManager defaultManager] runQueries];
        }
    //});
    
    [self incrementAppLaunchCount];
    
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([[LXSession thisSession] locationPermissionDetermined]) {
            [[LXSession thisSession] startLocationUpdates];
        }
    //});
    
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
   //[[LXServer shared] getAllBucketsWithSuccess:^(id responseObject){
   //                     completionHandler(UIBackgroundFetchResultNewData);
   //                 }failure:^(NSError *error){
   //                     completionHandler(UIBackgroundFetchResultNoData);
   //                 }];
}





# pragma mark - Notifications

- (void) getPushNotificationPermission
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:@"doneAskingForPushNotificationPermission"];
    //[userDefaults synchronize];
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[LXServer shared] updateDeviceToken:deviceToken success:^(id responseObject) {
            NSLog(@"My token is: %@", deviceToken);
        } failure:^(NSError *error){
            NSLog(@"Didn't successfully submit device token: %@", deviceToken);
        }
         ];
    //});
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"ITEM ID: %@", [userInfo objectForKey:@"item_id"]);
    //parse for variables
    if (active) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        return;
    }
    if ([userInfo objectForKey:@"bucket_id"] && [[userInfo objectForKey:@"bucket_id"] respondsToSelector:@selector(intValue)]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushBucketView" object:nil userInfo:@{@"bucket_id" : [userInfo objectForKey:@"bucket_id"]}];
    }
    if ([userInfo objectForKey:@"item_id"] && [[userInfo objectForKey:@"item_id"] respondsToSelector:@selector(intValue)]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushItemTableView" object:nil userInfo:@{@"item_id" : [userInfo objectForKey:@"item_id"]}];
    }
}


- (void) setBadgeIcon {
    if ([LXSession areNotificationsEnabled]) {
        if ([[[[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"] objectForKey:@"Recent"] firstObject] isAllNotesBucket]) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[[[[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"] objectForKey:@"Recent"] firstObject] objectForKey:@"items_count"] integerValue]];
        } else {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }
    }
}


# pragma mark other actions

- (void) incrementAppLaunchCount
{
    if (![[LXSession thisSession] user]) {
        return;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"appLaunches"]) {
        NSInteger appLaunches = [userDefaults integerForKey:@"appLaunches"];
        [userDefaults setInteger:appLaunches+1 forKey:@"appLaunches"];
        if (appLaunches%8 == 2 && ![[[LXSession thisSession] user] email] && [MFMailComposeViewController canSendMail]) {
            //EMAIL
            [self permissionsDelegate:@"email"];
        } else if ([userDefaults integerForKey:@"appLaunches"] > 7) {
            if (![LXSession areNotificationsEnabled] && (![userDefaults objectForKey:@"doneAskingForPushNotificationPermission"] && appLaunches%4 == 3)) {
                //PUSH NOTIFICATIONS
            } else if ([LXSession areNotificationsEnabled]) {
                [self getPushNotificationPermission];
            }
        }
    } else {
        [userDefaults setInteger:1 forKey:@"appLaunches"];
    }
    //[userDefaults synchronize];
}

- (void) permissionsDelegate:(NSString*)type
{
    if ([type isEqualToString:@"email"]) {
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = self;
        [mc setSubject:[NSString stringWithFormat:@"My Token: (%@==%@", [NSString userAuthToken], [[[LXSession thisSession] user] ID]]];
        [mc setMessageBody:@"Hit 'Send' in the top right corner to verify this email address! (and don't delete/change the subject of this email)\n\nVerify me! Cheers," isHTML:NO];
        [mc setToRecipients:@[@"thought@hppcmps.com"]];
        [self.window.rootViewController presentViewController:mc animated:YES completion:nil];
    }
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void) permissionsDelegate
{
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



@end
