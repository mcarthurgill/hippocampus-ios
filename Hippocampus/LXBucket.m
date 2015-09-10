//
//  LXBucket.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXBucket.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

static NSString *recentBucketsKey = @"recentBuckeyKeys";
static NSInteger maxRecentCount = 5;

@implementation NSMutableDictionary (LXBucket)

+ (void) bucketKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/buckets/keys" withMethod:@"GET" withParamaters:nil authType:@"user"
                           success:^(id responseObject){
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   if ([responseObject respondsToSelector:@selector(count)]) {
                                       [LXObjectManager assignLocal:responseObject WithLocalKey:@"bucketLocalKeys"];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedBucketLocalKeys" object:nil userInfo:nil];
                                   }
                               });
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           } failure:^(NSError* error){
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) refreshFromServerWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/detail.json", [self ID]] withMethod:@"GET" withParamaters:nil
                           success:^(id responseObject) {
                               
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   BOOL shouldRefresh = NO;
                                   
                                   NSMutableDictionary* bucket = [[responseObject objectForKey:@"bucket"] mutableCopy];
                                   if ([[responseObject objectForKey:@"object_type"] isEqualToString:@"all-thoughts"]) {
                                       [bucket setObject:[NSMutableDictionary allThoughtsLocalKey] forKey:@"local_key"];
                                   }
                                   
                                   NSMutableArray* oldItemKeys = [[NSMutableArray alloc] initWithArray:([[LXObjectManager objectWithLocalKey:[bucket localKey]] itemKeys] ? [[LXObjectManager objectWithLocalKey:[bucket localKey]] itemKeys] : @[])];
                                   
                                   if ([responseObject objectForKey:@"item_keys"] && NULL_TO_NIL([responseObject objectForKey:@"item_keys"])) {
                                       [bucket setObject:[responseObject objectForKey:@"item_keys"] forKey:@"item_keys"];
                                   }
                                   
                                   shouldRefresh = [bucket assignLocalVersionIfNeeded] || shouldRefresh;
                                   
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":bucket, @"oldItemKeys":oldItemKeys}];
                               });
                               
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

+ (NSString*) allThoughtsLocalKey
{
    return [NSString stringWithFormat:@"all-thoughts--%@", [[[LXSession thisSession] user] ID]];
}

+ (NSMutableDictionary*) allBucketNames
{
    NSArray* keys = [LXObjectManager objectWithLocalKey:@"bucketLocalKeys"];
    NSMutableDictionary* names = [[NSMutableDictionary alloc] init];
    for (NSString* key in keys) {
        NSMutableDictionary* bucket = [LXObjectManager objectWithLocalKey:key];
        if (bucket) {
            [names setObject:[bucket firstName] forKey:[bucket firstName]];
        }
    }
    return names;
}

+ (NSMutableArray*) recentBucketLocalKeys
{
    return [LXObjectManager objectWithLocalKey:recentBucketsKey] ? [[LXObjectManager objectWithLocalKey:recentBucketsKey] mutableCopy] : [@[] mutableCopy];
}

+ (void) addRecentBucketLocalKey:(NSString*)key
{
    NSMutableArray* keys = [self recentBucketLocalKeys];
    [keys removeObject:key];
    [keys insertObject:key atIndex:0];
    if ([keys count] > maxRecentCount) {
        [keys removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(maxRecentCount, ([keys count] - maxRecentCount))]];
    }
    [LXObjectManager assignLocal:keys WithLocalKey:recentBucketsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedBucketLocalKeys" object:nil];
}

+ (void) removeRecentBucketLocalKey:(NSString*)key
{
    NSMutableArray* keys = [self recentBucketLocalKeys];
    [keys removeObject:key];
    [LXObjectManager assignLocal:keys WithLocalKey:recentBucketsKey];
}

- (NSMutableArray*) items
{
    if ([self objectForKey:@"items"] && NULL_TO_NIL([self objectForKey:@"items"])) {
        return [self objectForKey:@"items"];
    } else {
        return [@[] mutableCopy];
    }
}

- (NSMutableArray*) itemKeys
{
    if ([self objectForKey:@"item_keys"] && NULL_TO_NIL([self objectForKey:@"item_keys"])) {
        return [self objectForKey:@"item_keys"];
    } else {
        return [@[] mutableCopy];
    }
}

- (NSString*) cachedItemMessage
{
    if ([self objectForKey:@"cached_item_message"] && NULL_TO_NIL([self objectForKey:@"cached_item_message"]))
        return [self objectForKey:@"cached_item_message"];
    return nil;
}

- (NSMutableDictionary*) itemAtIndex:(NSInteger)index
{
    return [LXObjectManager objectWithLocalKey:[[self itemKeys] objectAtIndex:index]] ? [LXObjectManager objectWithLocalKey:[[self itemKeys] objectAtIndex:index]] : [@{} mutableCopy];
}

- (UIColor*) bucketColor
{
    if ([[self ID] integerValue]%3 == 0) {
        return [UIColor SHColorGreen];
    } else if ([[self ID] integerValue]%3 == 1) {
        return [UIColor SHColorBlue];
    } else if ([[self ID] integerValue]%3 == 2) {
        return [UIColor SHColorOrange];
    }
    return [UIColor SHFontPurple];
}

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index
{
    //[[self items] insertObject:item atIndex:index];
    if (![self itemKeys]) {
        [self setObject:[[NSMutableArray alloc] init] forKey:@"item_keys"];
    }
    [self setObject:[NSMutableArray arrayWithArray:[self itemKeys]] forKey:@"item_keys"];
    [[self itemKeys] insertObject:[item localKey] atIndex:index];
    
    [self removeObjectForKey:@"updated_at"];
    [self assignLocalVersionIfNeeded];
    
    [item assignLocalVersionIfNeeded];
}

- (void) removeItemFromBucket:(NSMutableDictionary*)item
{
    if ([item localKey] && [self itemKeys]) {
        NSMutableArray* itemKeys = [[self itemKeys] mutableCopy];
        [itemKeys removeObject:[item localKey]];
        [self setObject:itemKeys forKey:@"item_keys"];
    }
    NSMutableArray* items = [[self items] mutableCopy];
    for (NSInteger i = 0; i < [items count]; ++i) {
        NSMutableDictionary* compareToItem = [items objectAtIndex:i];
        if ([[compareToItem localKey] isEqualToString:[item localKey]]) {
            [items removeObjectAtIndex:i];
            [self setObject:items forKey:@"items"];
            [self removeObjectForKey:@"updated_at"];
            [self assignLocalVersionIfNeeded];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"removedItemFromBucket" object:nil userInfo:@{@"item":item,@"bucket":self}];
            return;
        }
    }
}

- (BOOL) isAllThoughtsBucket
{
    return [self localKey] && [[self localKey] isEqualToString:[NSMutableDictionary allThoughtsLocalKey]];
}


@end
