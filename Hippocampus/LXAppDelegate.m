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
    //Default appearance
    [self.window setTintColor:[UIColor mainColor]];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:[[UIFont titleFont] fontName] size:13.0f]} forState:UIControlStateNormal];
    
    // Override point for customization after application launch.
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    //initialize the core data variables and put in the session
    [self managedObjectContext];
    [self persistentStoreCoordinator];
    [self managedObjectModel];
    
    [[LXSession thisSession] setVariables];
    
    if ([self shouldPresentIntroductionViews]) {
        [self setRootStoryboard:@"Login"];
    } else {
        [self setRootStoryboard:@"Seahorse"];
    }
    [self loadAddressBook];
    
    return YES;
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
    if ([name isEqualToString:@"Messages"] && [[LXSession thisSession] user]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[[LXSession thisSession] user] updateTimeZone];
        });
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    
    active = NO;
    
    NSManagedObjectContext *moc = [[LXSession thisSession] managedObjectContext];
    NSError* error;
    if (![moc save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    if ([[LXSession thisSession] user]) {
        [[LXServer shared] getAllBucketsWithSuccess:nil failure:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationWillResignActive" object:nil];
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[LXSession thisSession] attemptUnsavedNoteSaving];
    });
    [self incrementAppLaunchCount];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([[LXSession thisSession] locationPermissionDetermined]) {
            [[LXSession thisSession] startLocationUpdates];
        }
    });
    
    active = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

# pragma mark managed object context


// 1
- (NSManagedObjectContext *) managedObjectContext {
    if ([[LXSession thisSession] managedObjectContext] != nil) {
        return [[LXSession thisSession] managedObjectContext];
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        [LXSession thisSession].managedObjectContext = [[NSManagedObjectContext alloc] init];
        [[LXSession thisSession].managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return [LXSession thisSession].managedObjectContext;
}

//2
- (NSManagedObjectModel *)managedObjectModel {
    if ([[LXSession thisSession] managedObjectModel] != nil) {
        return [[LXSession thisSession] managedObjectModel];
    }
    [LXSession thisSession].managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return [LXSession thisSession].managedObjectModel;
}

//3
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if ([LXSession thisSession].persistentStoreCoordinator != nil) {
        return [LXSession thisSession].persistentStoreCoordinator;
    }
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory]
                                               stringByAppendingPathComponent: @"Model.sqlite"]];
    NSError *error = nil;
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    [LXSession thisSession].persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                                          initWithManagedObjectModel:[self managedObjectModel]];
    if(![[LXSession thisSession].persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                         configuration:nil URL:storeUrl options:options error:&error]) {
        /*Error for store creation should be handled in here*/
    }
    
    return [[LXSession thisSession] persistentStoreCoordinator];
}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}



# pragma mark - Background Fetch

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([[LXSession thisSession] user]) {
        [[[LXSession thisSession] user] updateTimeZone];
    }
   [[LXServer shared] getAllBucketsWithSuccess:^(id responseObject){
                        completionHandler(UIBackgroundFetchResultNewData);
                    }failure:^(NSError *error){
                        completionHandler(UIBackgroundFetchResultNoData);
                    }];
}



# pragma mark - Notifications

- (void) getPushNotificationPermission
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:@"doneAskingForPushNotificationPermission"];
    [userDefaults synchronize];
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[LXServer shared] updateDeviceToken:deviceToken success:^(id responseObject) {
            NSLog(@"My token is: %@", deviceToken);
        } failure:^(NSError *error){
            NSLog(@"Didn't successfully submit device token: %@", deviceToken);
        }
         ];
    });
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
        if (appLaunches%8 == 2 && ![[[LXSession thisSession] user] email] && [MFMailComposeViewController canSendMail]) { //if (![[[LXSession thisSession] user] email] && [MFMailComposeViewController canSendMail]) {
            NSLog(@"No email!");
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCPermissionViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"permissionViewController"];
            [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
            [vc setImageForMainImageView:[UIImage imageNamed:@"email-screen.jpg"]];
            [vc setMainLabelText:@"You can quickly email thoughts to your Hippocampus if you verify your email address. No spam, we promise."];
            [vc setPermissionType:@"email"];
            [vc setDelegate:self];
            [vc setButtonText:@"Verify Email"];
            [self.window.rootViewController presentViewController:vc animated:NO completion:nil];
        } else if ([userDefaults integerForKey:@"appLaunches"] > 7) {
            if (![LXSession areNotificationsEnabled] && (![userDefaults objectForKey:@"doneAskingForPushNotificationPermission"] && appLaunches%4 == 3)) {
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
                HCPermissionViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"permissionViewController"];
                [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
                [vc setImageForMainImageView:[UIImage imageNamed:@"permission-screen.jpg"]];
                [vc setMainLabelText:@"Turn on push notifications to get nudges (reminders) about your thoughts. No spam, we promise."];
                [vc setPermissionType:@"notifications"];
                [vc setDelegate:self];
                [vc setButtonText:@"Turn On Notifications"];
                [self.window.rootViewController presentViewController:vc animated:NO completion:nil];
            } else if ([LXSession areNotificationsEnabled]) {
                [self getPushNotificationPermission];
            }
        }
    } else {
        [userDefaults setInteger:1 forKey:@"appLaunches"];
    }
    [userDefaults synchronize];
}

- (void) permissionsDelegate:(NSString*)type
{
    NSLog(@"permissions delegate!");
    if ([type isEqualToString:@"email"]) {
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = self;
        [mc setSubject:[NSString stringWithFormat:@"My Token: (%@==%@", [NSString userAuthToken], [[[LXSession thisSession] user] ID]]];
        [mc setMessageBody:@"Hit 'Send' in the top right corner to verify this email address! (and don't delete/change the subject of this email)\n\nVerify me! Cheers," isHTML:NO];
        [mc setToRecipients:@[@"thought@hppcmps.com"]];
        // Present mail view controller on screen
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
    // Close the Mail Interface
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
