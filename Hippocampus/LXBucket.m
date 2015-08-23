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

- (void) refreshFromServerWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/detail.json", [self ID]] withMethod:@"GET" withParamaters:nil
                           success:^(id responseObject) {
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   BOOL shouldRefresh = NO;
                                   //for (NSMutableDictionary* item in [responseObject objectForKey:@"items"]) {
                                   //    shouldRefresh = [item updateLocalVersionIfNeeded] || shouldRefresh;
                                   //}
                                   NSMutableDictionary* bucket = [[responseObject objectForKey:@"bucket"] mutableCopy];
                                   [bucket setObject:[responseObject objectForKey:@"item_keys"] forKey:@"item_keys"];
                                   shouldRefresh = [bucket updateLocalVersionIfNeeded] || shouldRefresh;
                                   if (shouldRefresh) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":bucket}];
                                   }
                                   [[NSUserDefaults standardUserDefaults] synchronize];
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

- (NSMutableDictionary*) itemAtIndex:(NSInteger)index
{
    return [LXObjectManager objectWithLocalKey:[[self itemKeys] objectAtIndex:index]] ? [LXObjectManager objectWithLocalKey:[[self itemKeys] objectAtIndex:index]] : [@{} mutableCopy];
}

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index
{
    [[self items] insertObject:item atIndex:index];
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
