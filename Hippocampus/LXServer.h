//
//  LXServer.h
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXServer : AFHTTPSessionManager

+ (LXServer *)shared;

//objects
+ (id) getObjectFromModel:(NSString*)modelName primaryKeyName:(NSString*)primaryKeyName primaryKey:(NSString*)primaryKey;
+ (id) addToDatabase:(NSString*)modelName object:(NSDictionary*)object primaryKeyName:(NSString*)primaryKey withMapping:(NSDictionary*)mapping;
+ (void) addArrayToDatabase:(NSString*)modelName array:(NSArray*)array primaryKeyName:(NSString*)primaryKey withMapping:(NSDictionary*)mapping;
+ (void) saveObject:(id)object withPath:(NSString*)path method:(NSString*)method mapping:(NSDictionary*)mapping success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

//requests
- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)params constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;


//specific requests
- (void) getAllBucketsWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getBucketShowWithPage:(int)p bucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getAllItemsWithPage:(int)p success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) savebucketWithBucketID:(NSString*)bucketID andBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getMediaUrlsForBucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) deleteBucketWithBucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getNotesNearCurrentLocation:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getUpcomingRemindersWithPage:(int)p success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getRandomItemsWithLimit:(int)limit success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getSearchResults:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) createBucketWithFirstName:(NSString*)firstName andBucketType:(NSString*)bucketType success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) saveReminderForItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) saveUpdatedMessageForItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) updateItemInfoWithItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) addItem:(NSDictionary*)item toBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) removeItem:(NSDictionary*)item fromBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) updateDeviceToken:(NSData *)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
