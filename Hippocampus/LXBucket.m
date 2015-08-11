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
                                   for (NSMutableDictionary* item in [responseObject objectForKey:@"items"]) {
                                       shouldRefresh = [item updateLocalVersionIfNeeded] || shouldRefresh;
                                   }
                                   NSMutableDictionary* bucket = [[responseObject objectForKey:@"bucket"] mutableCopy];
                                   [bucket setObject:[responseObject objectForKey:@"items"] forKey:@"items"];
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

- (NSArray*) items
{
    if ([self objectForKey:@"items"] && NULL_TO_NIL([self objectForKey:@"items"])) {
        return [self objectForKey:@"items"];
    } else {
        return @[];
    }
}

- (NSMutableDictionary*) itemAtIndex:(NSInteger)index
{
    return [LXObjectManager objectWithLocalKey:[[[self items] objectAtIndex:index] localKey]] ? [LXObjectManager objectWithLocalKey:[[[self items] objectAtIndex:index] localKey]] : [[self items] objectAtIndex:index];
}

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index
{
    NSMutableArray* tempItems = [[self items] mutableCopy];
    [tempItems insertObject:item atIndex:index];
    [self setObject:tempItems forKey:@"items"];
    [self removeObjectForKey:@"updated_at"];
    [self saveLocal];
}


@end
