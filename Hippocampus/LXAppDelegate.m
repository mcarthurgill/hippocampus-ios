//
//  LXAppDelegate.m
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXAppDelegate.h"
#import "HCMainTabBarController.h"

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
//          [self setRootStoryboard:@"Main"];
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
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    NSLog(@"applicationWillResignActive");
    
    NSManagedObjectContext *moc = [[LXSession thisSession] managedObjectContext];
    NSError* error;
    if (![moc save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"openNewItemScreen" object:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[LXSession thisSession] attemptUnsavedNoteSaving];
    });
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


# pragma mark login methods

- (void) presentLoginViews:(BOOL)animated
{
    [(HCMainTabBarController*)self.window.rootViewController presentLoginViews:animated];
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

@end
