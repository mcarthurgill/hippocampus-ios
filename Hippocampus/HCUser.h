//
//  HCUser.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HCUser : NSManagedObject

@property (nonatomic, retain) NSNumber * loggedInUser;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSNumber * numberItems;
@property (nonatomic, retain) NSNumber * numberBuckets;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * updatedAt;
@property (nonatomic, retain) NSNumber * lastItemUpdateTime;
@property (nonatomic, retain) NSNumber * lastBucketUpdateTime;
@property (nonatomic, retain) NSNumber * setupCompletion;


// logged in user

+ (HCUser*) loggedInUser;
+ (void) loginUser:(NSString*)phone callingCode:(NSString*)callingCode success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
+ (void) tokenVerify:(NSString*)code phone:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
+ (void) loginWithToken:(NSString*)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) makeLoggedInUser;


// retrievals

- (void) getNewItemsSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getItems:(NSNumber*)lastUpdated success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getNewBucketsSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getBuckets:(NSNumber*)lastUpdated success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (NSString*) scoreString;


//setters

- (void) setUserStats:(NSMutableDictionary*)dict;

- (void) updateTimeZone;


//helpers

-(BOOL) completedSetup;

@end
