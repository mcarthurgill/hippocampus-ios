//
//  LXAppDelegate.m
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXAppDelegate.h"

@implementation LXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //initialize the core data variables and put in the session
    [self managedObjectContext];
    [self persistentStoreCoordinator];
    [self managedObjectModel];
    
    [[LXSession thisSession] setVariables];
    
    if ([self shouldPresentIntroductionViews]) {
        [self setRootStoryboard:@"Login"];
    } else {
        [self setRootStoryboard:@"Messages"];
    }
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    return YES;
}

- (BOOL) shouldPresentIntroductionViews
{
    NSLog(@"USER: %@", [[LXSession thisSession] user]);
    return ![[LXSession thisSession] user];
}

- (void) setRootStoryboard:(NSString*)name
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:name bundle:[NSBundle mainBundle]];
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    
    NSManagedObjectContext *moc = [[LXSession thisSession] managedObjectContext];
    NSError* error;
    if (![moc save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    if ([HCUser loggedInUser]) {
        [[LXServer shared] getAllBucketsWithSuccess:nil failure:nil];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[LXSession thisSession] attemptUnsavedNoteSaving];
    });
    [self incrementAppLaunchCount];
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
   [[LXServer shared] getAllBucketsWithSuccess:^(id responseObject){
                        completionHandler(UIBackgroundFetchResultNewData);
                    }failure:^(NSError *error){
                        completionHandler(UIBackgroundFetchResultNoData);
                    }];
}



# pragma mark - Notifications

- (void) getPushNotificationPermission
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound];
    }
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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

- (void) setBadgeIcon
{
    UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (grantedSettings.types && UIUserNotificationTypeBadge) {
        if ([[[[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"] objectForKey:@"Recent"] firstObject] isAllNotesBucket]) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[[[[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"] objectForKey:@"Recent"] firstObject] objectForKey:@"items_count"] integerValue]];
        } else {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        }
    }
}

- (void) incrementAppLaunchCount
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"appLaunches"]) {
        NSInteger appLaunches = [userDefaults integerForKey:@"appLaunches"];
        [userDefaults setInteger:appLaunches+1 forKey:@"appLaunches"];
        if ([userDefaults integerForKey:@"appLaunches"] > 7) {
            [self getPushNotificationPermission];
        }
    } else {
        [userDefaults setInteger:1 forKey:@"appLaunches"];
    }
    [userDefaults synchronize];
}


@end
