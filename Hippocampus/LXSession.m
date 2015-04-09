//
//  LXSession.m
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXSession.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

static LXSession* thisSession = nil;

@implementation LXSession

@synthesize user;

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;

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
    HCUser* u = [HCUser loggedInUser];
    if (u) {
        [self setUser:u];
    }
}


# pragma mark unsaved notes dictionary


- (NSMutableArray*) unsavedNotes
{
    NSMutableArray* temp = [[NSMutableArray alloc] init];
    NSArray* keys = [[self unsavedNotesDictionary] allKeys];
    for (NSString* k in keys) {
        [temp addObjectsFromArray:[[self unsavedNotesDictionary] objectForKey:k]];
    }
    return temp;
}

- (NSMutableDictionary*) unsavedNotesDictionary
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"unsavedNotes"]) {
        return [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"unsavedNotes"]];
    }
    return [[NSMutableDictionary alloc] init];
}

- (NSMutableArray*) unsavedNotesForBucket:(NSString*)bucketID
{
    if ([[self unsavedNotesDictionary] objectForKey:bucketID]) {
        return [[NSMutableArray alloc] initWithArray:[[self unsavedNotesDictionary] objectForKey:bucketID]];
    }
    return nil;
}

- (void) addUnsavedNote:(NSMutableDictionary*)note toBucket:(NSString*)bucketID
{
    NSMutableDictionary* temp = [self unsavedNotesDictionary];
    NSMutableArray* tempArray = [self unsavedNotesForBucket:bucketID];
    if (!tempArray) {
        tempArray = [[NSMutableArray alloc] init];
    }
    [tempArray addObject:note];
    [temp setObject:tempArray forKey:bucketID];
    [[NSUserDefaults standardUserDefaults] setObject:temp forKey:@"unsavedNotes"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) removeUnsavedNote:(NSMutableDictionary*)note fromBucket:(NSString*)bucketID
{
    NSMutableDictionary* temp = [self unsavedNotesDictionary];
    NSMutableArray* tempArray = [self unsavedNotesForBucket:bucketID];
    if (tempArray) {
        for (NSDictionary* dict in tempArray) {
            if ([[dict objectForKey:@"device_timestamp"] isEqualToString:[note objectForKey:@"device_timestamp"]]) {
                [tempArray removeObject:dict];
            }
        }
    }
    if (tempArray && [tempArray count] > 0) {
        [temp setObject:tempArray forKey:bucketID];
    } else {
        [temp removeObjectForKey:bucketID];
    }
    [[NSUserDefaults standardUserDefaults] setObject:temp forKey:@"unsavedNotes"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) updateNoteToSaved:(NSDictionary*)newNote inBucket:(NSString*)bucketID
{
    NSMutableArray* tempArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:bucketID]];
    NSMutableArray* copyArray = [NSMutableArray arrayWithArray:tempArray];
    if (tempArray) {
        for (NSDictionary* dict in tempArray) {
            if ([[dict objectForKey:@"device_timestamp"] isEqualToString:[newNote objectForKey:@"device_timestamp"]]) {
                [copyArray replaceObjectAtIndex:[tempArray indexOfObject:dict] withObject:[newNote cleanDictionary]];
            }
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:copyArray forKey:bucketID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) attemptNoteSave:(NSDictionary*)note success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSMutableDictionary* unsavedNote = [[NSMutableDictionary alloc] initWithDictionary:note];
    NSMutableArray* mediaURLS = [[NSMutableArray alloc] initWithArray:[unsavedNote objectForKey:@"media_urls"]];
    [unsavedNote removeObjectForKey:@"media_urls"];
    [[LXServer shared] requestPath:@"/items.json" withMethod:@"POST" withParamaters:@{@"item":unsavedNote}
         constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
             if (mediaURLS && [mediaURLS count] > 0) {
                 if ([NSData dataWithContentsOfFile:[mediaURLS firstObject]]) {
                     [formData appendPartWithFileData:[NSData dataWithContentsOfFile:[mediaURLS firstObject]] name:@"file" fileName:@"image.jpg" mimeType:@"image/jpeg"];
                 }
             }
         }
                           success:^(id responseObject) {
                               [self removeUnsavedNote:responseObject fromBucket:[NSString stringWithFormat:@"%@",[unsavedNote objectForKey:@"bucket_id"]]];
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError* error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) attemptUnsavedNoteSaving
{
    NSMutableArray* notes = [self unsavedNotes];
    for (NSDictionary* note in notes) {
        [self attemptNoteSave:note
                      success:^(id responseObject) {
                          [self removeUnsavedNote:responseObject fromBucket:[note objectForKey:@"bucket_id"]];
                          [self updateNoteToSaved:[NSDictionary dictionaryWithDictionary:responseObject] inBucket:[NSString stringWithFormat:@"%@",[note objectForKey:@"bucket_id"]]];
                      }
                      failure:^(NSError* error) {
                          NSLog(@"couldn't save note!");
                      }
         ];
    }
}

+ (NSString*) documentsPathForFileName:(NSString*) name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    return [documentsPath stringByAppendingPathComponent:name];
}

+ (NSString*) writeImageToDocumentsFolder:(UIImage *)image
{
    // Get image data. Here you can use UIImagePNGRepresentation if you need transparency
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    // Get image path in user's folder and store file with name image_CurrentTimestamp.jpg (see documentsPathForFileName below)
    NSString *imagePath = [self documentsPathForFileName:[NSString stringWithFormat:@"image_%f.jpg", [NSDate timeIntervalSinceReferenceDate]]];
    // Write image data to user's folder
    [imageData writeToFile:imagePath atomically:YES];
    return imagePath;
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

+ (BOOL) locationPermissionDetermined
{
    if ([CLLocationManager locationServicesEnabled]) {
        NSLog(@"Location Services Enabled");
        if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied) {
            NSLog(@"locationDenied!");
        } else if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorized) {
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
    
    if ([LXSession locationPermissionDetermined]) {
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
    
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    if (types & UIRemoteNotificationTypeAlert){
        return YES;
    } else{
        return NO;
    }
}

# pragma mark - Name

- (NSString*)myName
{
    NSString *ownerName = [[UIDevice currentDevice] name];
    
    NSRange t = [ownerName rangeOfString:@"'s"];
    if (t.location != NSNotFound) {
        ownerName = [ownerName substringToIndex:t.location];
    }
    return ownerName;
}

@end
