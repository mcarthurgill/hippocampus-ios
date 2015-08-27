//
//  LXBucket.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXBucket.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation NSMutableDictionary (LXBucket)

+ (void) bucketKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/buckets/keys" withMethod:@"GET" withParamaters:nil authType:@"user"
                           success:^(id responseObject){
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   if ([responseObject respondsToSelector:@selector(count)]) {
                                       [[[LXObjectManager defaultManager] library] setObject:responseObject forKey:@"bucketLocalKeys"];
                                       [[NSUserDefaults standardUserDefaults] setObject:responseObject forKey:@"bucketLocalKeys"];
                                       //[[NSUserDefaults standardUserDefaults] synchronize];
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
                                   if ([responseObject objectForKey:@"item_keys"] && NULL_TO_NIL([responseObject objectForKey:@"item_keys"])) {
                                       [bucket setObject:[responseObject objectForKey:@"item_keys"] forKey:@"item_keys"];
                                   }
                                   shouldRefresh = [bucket assignLocalVersionIfNeeded] || shouldRefresh;
                                   //if (shouldRefresh) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":bucket}];
                                   //}
                                   //[[NSUserDefaults standardUserDefaults] synchronize];
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

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index
{
    //[[self items] insertObject:item atIndex:index];
    [[self itemKeys] insertObject:[item localKey] atIndex:index];
    
    [self removeObjectForKey:@"updated_at"];
    [self saveLocal];
    
    [item saveLocal];
}

- (void) removeItemFromBucket:(NSMutableDictionary*)item
{
    NSMutableArray* items = [[self items] mutableCopy];
    for (NSInteger i = 0; i < [items count]; ++i) {
        NSMutableDictionary* compareToItem = [items objectAtIndex:i];
        if ([[compareToItem localKey] isEqualToString:[item localKey]]) {
            [items removeObjectAtIndex:i];
            [self setObject:items forKey:@"items"];
            [self removeObjectForKey:@"updated_at"];
            [self saveLocal];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"removedItemFromBucket" object:nil userInfo:@{@"item":item,@"bucket":self}];
            return;
        }
    }
}


@end
