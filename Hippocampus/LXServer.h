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


//requests
- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)params constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
    ///with auth
- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params authType:(NSString*)authType success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)params authType:(NSString*)authType constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

+ (BOOL) errorBecauseOfBadConnection:(NSInteger)code;

//specific requests
- (void) getAllBucketsWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getBucketShowWithPage:(int)p bucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getBucketInfoWithPage:(int)p bucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getAllItemsWithPage:(int)p success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) savebucketWithBucketID:(NSString*)bucketID andBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getMediaUrlsForBucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) deleteBucketWithBucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getItemsNearCenterX:(CGFloat)centerX andCenterY:(CGFloat)centerY andDX:(CGFloat)dx andDY:(CGFloat)dy success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getUpcomingRemindersWithPage:(int)p success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getRandomItemsWithLimit:(int)limit success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getSearchResults:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) createBucketWithFirstName:(NSString*)firstName andBucketType:(NSString*)bucketType success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) createBucketWithFirstName:(NSString*)firstName andGroupID:(NSString*)groupID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) saveReminderForItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) saveUpdatedMessageForItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) updateItemInfoWithItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) updateUser:(NSDictionary*)params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) addItem:(NSDictionary*)item toBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) removeItem:(NSDictionary*)item fromBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) updateDeviceToken:(NSData *)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getItemsNearCurrentLocation:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) createContactCardWithBucket:(NSDictionary*)bucket andContact:(NSMutableDictionary*)contact success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) createBucketUserPairsWithContacts:(NSMutableArray*)contacts andBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) deleteBucketUserPairWithBucketID:(NSString*)bucketID andPhoneNumber:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) getSetupQuestionsForPercentage:(NSString*)percentage success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) submitResponseToSetupQuestion:(NSString*)response success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) deleteContactCard:(NSMutableDictionary*)contact success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
