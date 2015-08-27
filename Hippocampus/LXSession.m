//
//  LXSession.m
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXSession.h"
#import "LXObjects.h"


#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

static LXSession* thisSession = nil;

@implementation LXSession

@synthesize verifyingTokens;

@synthesize cachedUser;

@synthesize backgroundTask;

@synthesize locationManager;

//constructor
-(id) init
{
    if (thisSession) {
        return thisSession;
    }
    self = [super init];
    return self;
}


//singleton instance
+(LXSession*) thisSession
{
    if (!thisSession) {
        thisSession = [[super allocWithZone:NULL] init];
    }
    return thisSession;
}


//prevent creation of additional instances
+(id)allocWithZone:(NSZone *)zone
{
    return [self thisSession];
}


//set singleton variables
- (void) setVariables
{
}

- (NSMutableDictionary*) user
{
    if (self.cachedUser) {
        return self.cachedUser;
    } else {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"localUserKey"]) {
            NSMutableDictionary *u = [LXObjectManager objectWithLocalKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"localUserKey"]];
            [self setCachedUser:u];
            return u;
        } else {
            return nil;
        }
    }
}


# pragma mark unsaved notes dictionary


- (NSString*) documentsPathForFileName:(NSString*) name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    return [documentsPath stringByAppendingPathComponent:name];
}

- (NSString*) writeImageToDocumentsFolder:(UIImage *)image
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
    
    // Get image path in user's folder and store file with name image_CurrentTimestamp.jpg (see documentsPathForFileName below)
    NSString *imagePath = [self documentsPathForFileName:[NSString stringWithFormat:@"image_%f.jpg", [NSDate timeIntervalSinceReferenceDate]]];
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    [imageData writeToFile:imagePath atomically:YES];
    
    [self endBackgroundUpdateTask];
    
    return imagePath;
}


- (void) endBackgroundUpdateTask
{
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
}

+ (CLLocation*) currentLocation
{
    if ([[LXSession thisSession] locationManager]) {
        return [[[LXSession thisSession] locationManager] location];
    }
    return nil;
}

- (BOOL) hasLocation
{
    return ([self locationManager] && [[self locationManager] location]);
}

- (BOOL) locationPermissionDetermined
{
    if ([CLLocationManager locationServicesEnabled]) {
        NSLog(@"Location Services Enabled");
        if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied) {
            NSLog(@"locationDenied!");
        } else if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedAlways) {
            NSLog(@"location authorized!");
        } else if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] ==kCLAuthorizationStatusAuthorizedWhenInUse) {
            NSLog(@"new location authorized!");
        } else {
            NSLog(@"indeterminate!");
            return NO;
        }
    }
    return YES;
}

- (void) startLocationUpdates
{
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    if ([self locationPermissionDetermined]) {
        [self getCurrentLocation];
    } else {
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            [self.locationManager startUpdatingLocation];
        }
    }
}

- (void) getCurrentLocation
{
    NSLog(@"getting current location!");
    locationManager.distanceFilter = 50.0;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self getCurrentLocation];
    }
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *myLocation = [locations lastObject];
    //[manager stopUpdatingLocation];
    NSLog(@"LATITUDE, LONGITUDE: %f, %f", myLocation.coordinate.latitude, myLocation.coordinate.longitude);
}




# pragma mark - Push Notifications

+ (BOOL) areNotificationsEnabled
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]){
        UIUserNotificationSettings *noticationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (!noticationSettings || (noticationSettings.types == UIUserNotificationTypeNone)) {
            return NO;
        }
        return YES;
    }
    return NO;
}




- (void) addVerifyingToken:(NSString *)token
{
    if (!self.verifyingTokens) {
        self.verifyingTokens = [[NSMutableArray alloc] init];
    }
    [self.verifyingTokens addObject:token];
}







# pragma mark logging in user


+ (void) loginUser:(NSString*)phone callingCode:(NSString*)callingCode success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/passcode.json" withMethod:@"POST" withParamaters:@{ @"phone": phone, @"calling_code" : callingCode}
                           success:^(id responseObject) {
                               //HCUser* user = [LXServer addToDatabase:@"HCUser" object:responseObject primaryKeyName:@"userID" withMapping:[HCUser resourceKeysForPropertyKeys]];
                               //[user makeLoggedInUser];
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

+ (void) tokenVerify:(NSString*)code phone:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/session.json" withMethod:@"POST" withParamaters:@{@"phone": phone, @"passcode": code }
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"] && [responseObject objectForKey:@"user"]) {
                                   NSMutableDictionary* user = [[responseObject objectForKey:@"user"] mutableCopy];
                                   [user makeLoggedInUser];
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

+ (void) loginWithToken:(NSString*)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/session_token.json" withMethod:@"POST" withParamaters:@{@"token": token }
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"] && [responseObject objectForKey:@"user"]) {
                                   NSMutableDictionary* user = [[responseObject objectForKey:@"user"] mutableCopy];
                                   [user makeLoggedInUser];
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

@end
