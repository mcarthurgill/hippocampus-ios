//
//  LXSession.h
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@interface LXSession : NSObject <CLLocationManagerDelegate>

+ (LXSession*) thisSession;

- (NSMutableDictionary*) user;
@property (strong, nonatomic) NSMutableDictionary* cachedUser;
@property (strong, nonatomic) NSMutableDictionary* permissionsAsked;

@property (strong, nonatomic) NSMutableArray* verifyingTokens;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) CLLocationManager* locationManager;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

- (void) setVariables;

- (NSString*) documentsPathForFileName:(NSString*) name;
- (NSString*) writeImageToDocumentsFolder:(UIImage*)image;


+ (CLLocation*) currentLocation;
- (BOOL) hasLocation;
- (BOOL) locationPermissionDetermined;
- (void) startLocationUpdates;

+ (BOOL) areNotificationsEnabled;


- (void) addVerifyingToken:(NSString*)token;


// logging in user

+ (void) loginUser:(NSString*)phone callingCode:(NSString*)callingCode success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
+ (void) tokenVerify:(NSString*)code phone:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
+ (void) loginWithToken:(NSString*)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
