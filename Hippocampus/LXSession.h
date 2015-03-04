//
//  LXSession.h
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCUser.h"
#import <CoreLocation/CoreLocation.h>

@interface LXSession : NSObject <CLLocationManagerDelegate>

+(LXSession*) thisSession;

@property (strong, nonatomic) HCUser* user;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) CLLocationManager* locationManager;

- (void) setVariables;




- (NSMutableArray*) unsavedNotes;
- (NSMutableDictionary*) unsavedNotesDictionary;
- (NSMutableArray*) unsavedNotesForBucket:(NSString*)bucketID;

- (void) addUnsavedNote:(NSMutableDictionary*)note toBucket:(NSString*)bucketID;
- (void) removeUnsavedNote:(NSMutableDictionary*)note fromBucket:(NSString*)bucketID;

- (void) attemptNoteSave:(NSDictionary*)unsavedNote success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) attemptUnsavedNoteSaving;

+ (NSString*) documentsPathForFileName:(NSString*) name;
+ (NSString*) writeImageToDocumentsFolder:(UIImage*)image;



+ (CLLocation*) currentLocation;
- (BOOL) hasLocation;
+ (BOOL) locationPermissionDetermined;
- (void) startLocationUpdates;

@end
