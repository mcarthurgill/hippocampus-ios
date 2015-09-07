//
//  LXItem.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXItem.h"

@implementation NSMutableDictionary (LXItem)

+ (NSMutableDictionary*) createItemWithMessage:(NSString*)message
{
    NSMutableDictionary* i = [NSMutableDictionary create:@"item"];
    [i setObject:message forKey:@"message"];
    [i setObject:[[[LXSession thisSession] user] ID] forKey:@"user_id"];
    return i;
}

- (void) destroyItem
{
    if ([self belongsToCurrentUser]) {
        //remove from all items
        [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] removeItemFromBucket:self];
        //remove from each bucket
        for (NSMutableDictionary* bucket in [self buckets]) {
            [bucket removeItemFromBucket:self];
        }
        [self destroyBoth];
    }
}

- (BOOL) hasMedia
{
    return [[self media] count] > 0;
}

- (NSMutableArray*) media
{
    if ([self objectForKey:@"media_cache"] && NULL_TO_NIL([self objectForKey:@"media_cache"]) && [[self objectForKey:@"media_cache"] respondsToSelector:@selector(count)]) {
        return [self objectForKey:@"media_cache"];
    }
    return [@[] mutableCopy];
}


- (BOOL) shouldShowAvatar
{
    return ![self belongsToCurrentUser]; // should also: || isCollaborativeThread
}

- (NSString*) avatarURLString
{
    return [NSString stringWithFormat:@"%@/avatar/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"APIRoot"], [self userID]];
}



- (NSMutableArray*) bucketsArray
{
    return [self objectForKey:@"buckets_array"];
}


- (void) updateBucketsWithLocalKeys:(NSMutableArray*)newLocalKeys success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //OLD BUCKET KEYS
    NSMutableArray* removedFromBucketKeys = [[NSMutableArray alloc] init];
    if ([self bucketsArray]) {
        for (NSMutableDictionary* oldStub in [self bucketsArray]) {
            [removedFromBucketKeys addObject:[oldStub localKey]];
        }
    }
    //CREATE NEW BUCKETS ARRAY
    NSMutableArray* newBucketsArray = [[NSMutableArray alloc] init];
    for (NSString* key in newLocalKeys) {
        NSMutableDictionary* tempBucket = [LXObjectManager objectWithLocalKey:key];
        if (tempBucket) {
            [newBucketsArray addObject:tempBucket];
            //ADD TO BUCKET ON DISK
            if ([tempBucket itemKeys] && ![[tempBucket itemKeys] containsObject:[self localKey]]) {
                NSMutableArray* tempItemKeys = [[tempBucket itemKeys] mutableCopy];
                [tempItemKeys addObject:[self localKey]];
                [tempBucket setObject:tempItemKeys forKey:@"item_keys"];
                [tempBucket removeObjectForKey:@"updated_at"];
                [tempBucket assignLocalVersionIfNeeded];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":tempBucket}];
            }
        }
        if ([removedFromBucketKeys containsObject:key]) {
            [removedFromBucketKeys removeObject:key];
        }
    }
    //REMOVE FROM THESE BUCKETS
    for (NSString* key in removedFromBucketKeys) {
        NSMutableDictionary* tempBucket = [LXObjectManager objectWithLocalKey:key];
        if (tempBucket && [tempBucket itemKeys]) {
            NSMutableArray* tempItemKeys = [[tempBucket itemKeys] mutableCopy];
            [tempItemKeys removeObject:[self localKey]];
            [tempBucket setObject:tempItemKeys forKey:@"item_keys"];
            [tempBucket removeObjectForKey:@"updated_at"];
            [tempBucket assignLocalVersionIfNeeded];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":tempBucket}];
        }
    }
    //SAVE THIS ITEM
    [self setObject:newBucketsArray forKey:@"buckets_array"];
    [self setObject:([newBucketsArray count] > 0 ? @"assigned" : @"outstanding") forKey:@"status"];
    [self removeObjectForKey:@"updated_at"];
    [self assignLocalVersionIfNeeded];
    NSLog(@"new object: %@", self);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshedObject" object:nil userInfo:self];
    //SEND TO SERVER
    [[LXServer shared] requestPath:@"/items/update_buckets" withMethod:@"PUT" withParamaters:@{@"local_key":[self localKey],@"local_keys":newLocalKeys} authType:@"user"
                           success:^(id responseObject) {
                               //SAVE LOCALLY
                               NSLog(@"response: %@", responseObject);
                               [[responseObject mutableCopy] assignLocalVersionIfNeeded];
                               [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshedObject" object:nil userInfo:responseObject];
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError* error) {
                               [[LXObjectManager defaultManager] addQuery:@"/items/update_buckets" withMethod:@"PUT" withObject:@{@"local_key":[self localKey],@"local_keys":newLocalKeys} withAuthType:@"user"];
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}


@end
