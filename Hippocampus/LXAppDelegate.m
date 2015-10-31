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
#import "SHMessagesViewController.h"
#import "SHItemViewController.h"

@implementation LXAppDelegate

@synthesize client;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentTutorial) name:@"presentTutorial" object:nil];
    
    //flush images from SGImageCache
    [SGImageCache flushImagesOlderThan:([[[NSDate alloc] init] timeIntervalSinceNow]+64*24*60*60)];
    
    [self setupAppearance];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [[LXSession thisSession] setVariables];
    
    if ([self shouldPresentIntroductionViews]) {
        [self setRootStoryboard:@"Login"];
    } else {
        [self setRootStoryboard:@"Seahorse"];
    }
    [self loadAddressBook];
    
    [self handleAppLaunch];
    
    [self setupPusher];
    
    return YES;
}

- (void) setupAppearance
{
    //Default appearance
    [self.window setTintColor:[UIColor mainColor]];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont titleFontWithSize:13.0f]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont titleFontWithSize:14.0f]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor mainColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont titleFontWithSize:16.0f], NSForegroundColorAttributeName : [UIColor SHFontDarkGray]}];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName:[UIFont titleFontWithSize:14.0f]}];
    
    // Override point for customization after application launch.
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
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
    [[LXObjectManager defaultManager] refreshObjectTypes:@"tags" withAboveUpdatedAt:nil
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
        [[[LXSession thisSession] user] updateTimeZone];
        [self refreshObjects];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    
    active = NO;
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
        }];
        [LXObjectManager saveToDisk];
        [[UIApplication sharedApplication] endBackgroundTask:bgt];
    //});
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
    
    if ([[LXSession thisSession] locationPermissionDetermined]) {
        [[LXSession thisSession] startLocationUpdates];
        //[[LXSession thisSession] performSelector:@selector(startLocationUpdates) withObject:nil afterDelay:2];
    }
    
    [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] refreshFromServerWithSuccess:^(id responseObject){} failure:^(NSError* error){}];
    
    active = YES;
    [self.client connect];
    
    [self incrementApplicationDidBecomeActiveCount];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

- (void) incrementApplicationDidBecomeActiveCount
{
    NSString* applicationDidBecomeActiveCount = [LXObjectManager objectWithLocalKey:@"applicationDidBecomeActiveCount"];
    if (!applicationDidBecomeActiveCount) {
        applicationDidBecomeActiveCount = [NSString stringWithFormat:@"0"];
    }
    applicationDidBecomeActiveCount = [NSString stringWithFormat:@"%li", (long)([applicationDidBecomeActiveCount integerValue]+1)];
    [LXObjectManager assignLocal:applicationDidBecomeActiveCount WithLocalKey:@"applicationDidBecomeActiveCount" alsoToDisk:YES];
    
    NSLog(@"launch count: %@", applicationDidBecomeActiveCount);
}


# pragma mark - Background Fetch

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([[LXSession thisSession] user]) {
        [[[LXSession thisSession] user] updateTimeZone];
        [[LXObjectManager defaultManager] refreshObjectTypes:@"items" withAboveUpdatedAt:nil
                                                     success:^(id responseObject){
                                                     }
                                                     failure:^(NSError* error) {
                                                     }
         ];
        [[LXObjectManager defaultManager] refreshObjectTypes:@"buckets" withAboveUpdatedAt:nil
                                                     success:^(id responseObject){
                                                     }
                                                     failure:^(NSError* error) {
                                                     }
         ];
        [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] refreshFromServerWithSuccess:^(id responseObject){
            [self setBadgeIcon];
            //[LXObjectManager saveToDisk];
            completionHandler(UIBackgroundFetchResultNewData);
        } failure:^(NSError* error){
            completionHandler(UIBackgroundFetchResultNewData);
        }];
    } else {
        completionHandler(UIBackgroundFetchResultNewData);
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
    //[self performSelector:@selector(registerDeviceToken:) withObject:deviceToken afterDelay:3];
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
    } else {
        [self setBadgeIcon];
    }
    
    if ([userInfo objectForKey:@"object_type"] && [[userInfo objectForKey:@"object_type"] respondsToSelector:@selector(length)] && [userInfo objectForKey:@"local_key"]) {
        if ([[userInfo objectForKey:@"object_type"] isEqualToString:@"item"]) {
            SHItemViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHItemViewController"];
            [vc setLocalKey:[userInfo objectForKey:@"local_key"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"pushViewController" object:nil userInfo:@{@"viewController":vc,@"animated":@NO}];
        } else if ([[userInfo objectForKey:@"object_type"] isEqualToString:@"bucket"]) {
            SHMessagesViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMessagesViewController"];
            [vc setLocalKey:[userInfo objectForKey:@"local_key"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"pushViewController" object:nil userInfo:@{@"viewController":vc,@"animated":@NO}];
        }
    }
    
}


- (void) setBadgeIcon
{
    if ([LXSession areNotificationsEnabled]) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[NSMutableDictionary unassignedThoughtCount]];
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

- (void) presentTutorial
{
    UIViewController* vc = (UIViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHAppPreviewViewController"];
    [self.window.rootViewController presentViewController:vc animated:NO completion:^(void){
    }];
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




# pragma mark pusher

- (void) setupPusher
{
    self.client = [PTPusher pusherWithKey:@"eee901e37beed226fa78" delegate:self encrypted:YES];
    [self.client connect];
    NSLog(@"channel %@", [NSString stringWithFormat:@"user-%@", [[[LXSession thisSession] user] ID]]);
    PTPusherChannel *channel = [self.client subscribeToChannelNamed:[NSString stringWithFormat:@"user-%@", [[[LXSession thisSession] user] ID]]];
    [channel bindToEventNamed:@"item-save" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictionary of the JSON object received
        if ([[channelEvent data] objectType] && [[[channelEvent data] objectType] isEqualToString:@"item"]) {
            [LXObjectManager assignObject:[channelEvent data]];
            if (![[channelEvent data] belongsToCurrentUser] || [[channelEvent data] isOutstanding]) {
                [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] refreshFromServerWithSuccess:^(id responseObject){} failure:nil];
            }
        }
    }];
    [channel bindToEventNamed:@"bucket-save" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictionary of the JSON object received
        if ([[channelEvent data] objectType] && [[[channelEvent data] objectType] isEqualToString:@"bucket"]) {
            [LXObjectManager assignObject:[channelEvent data]];
            [[[channelEvent data] mutableCopy] refreshFromServerWithSuccess:^(id responseObject){} failure:nil];
        }
    }];
}



@end
