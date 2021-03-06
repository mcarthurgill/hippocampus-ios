//
//  LXBucket.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LXBucket)

- (void) destroyBucket;

+ (NSString*) allThoughtsLocalKey;

+ (void) bucketKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (void) refreshFromServerWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index;

- (void) removeItemFromBucket:(NSMutableDictionary*)item;


+ (NSMutableDictionary*) allBucketNames;

+ (NSMutableArray*) recentBucketLocalKeys;
+ (void) addRecentBucketLocalKey:(NSString*)key;
+ (void) removeRecentBucketLocalKey:(NSString*)key;

- (NSMutableArray*) items;
- (NSMutableArray*) itemKeys;
- (NSString*) cachedItemMessage;

- (NSArray*) authorizedUsers;

- (NSMutableDictionary*) itemAtIndex:(NSInteger)index;

- (NSString*) relationLevel;
- (UIColor*) bucketColor;

- (NSMutableArray*) tagsArray;
- (NSMutableArray*) tagsArrayExcludingKey:(NSString*)key;
- (BOOL) hasTags;
- (BOOL) hasTagsExcludingKey:(NSString*)key;

- (BOOL) isAllThoughtsBucket;

- (BOOL) hasAuthorizedUserID:(NSString*)uID;

- (void) addCollaboratorsWithContacts:(NSMutableArray*)contacts success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) removeCollaboratorWithPhone:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) changeNameInBucketWithBucketUserPair:(NSMutableDictionary *)bup andNewName:(NSString*)newName success:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback;

- (void) updateTagsWithLocalKeys:(NSMutableArray*)newLocalKeys success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end

