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

@end
