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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshedObject" object:nil userInfo:self];
    NSLog(@"item: %@", [LXObjectManager objectWithLocalKey:[self localKey]]);
    //SEND TO SERVER
    [[LXServer shared] requestPath:@"/items/update_buckets" withMethod:@"PUT" withParamaters:@{@"local_key":[self localKey],@"local_keys":newLocalKeys} authType:@"user"
                           success:^(id responseObject) {
                               //SAVE LOCALLY
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


- (CGFloat) estimatedCellHeight
{
    CGFloat THOUGHT_LEFT_SIDE_MARGIN = 29.0f;
    CGFloat THOUGHT_RIGHT_SIDE_MARGIN = 27.0f;
    CGFloat THOUGHT_TOP_SIDE_MARGIN = 18.0f;
    CGFloat THOUGHT_BOTTOM_SIDE_MARGIN = 18.0f;
    CGFloat SCREEN_WIDTH = [[UIScreen mainScreen] bounds].size.width;
    CGFloat CONTENT_WIDTH = SCREEN_WIDTH-(THOUGHT_LEFT_SIDE_MARGIN+THOUGHT_RIGHT_SIDE_MARGIN);
    
    CGFloat messageHeight = 0.0f;
    if ([self hasMessage]) {
        messageHeight = [[self message] heightForTextWithWidth:CONTENT_WIDTH font:[UIFont itemContentFont]];
    }
    
    CGFloat imageHeight = 0;
    if ([self hasMedia]) {
        if (![self media] || [[self media] count] == 0) {
            imageHeight = 0;
        } else if ([[self media] count] == 1 && ![self hasMessage]) {
            //full width
            imageHeight = [[[self media] firstObject] heightForWidth:CONTENT_WIDTH];
        } else if ([[self media] count] == 1) {
            //2/5 of screen
            imageHeight = [[[self media] firstObject] heightForWidth:((CONTENT_WIDTH-10.0f)*2.0f/5.0f)];
            messageHeight = [[self message] heightForTextWithWidth:((CONTENT_WIDTH-10.0f)*3.0f/5.0f) font:[UIFont itemContentFont]];
            if (imageHeight >= messageHeight) {
                messageHeight = 0;
            } else {
                imageHeight = 0;
            }
        } else if ([[self media] count]%2==0) {
            //two per row
            imageHeight = 0;
            CGFloat currentAggregateWidth = 0;
            CGFloat currentAdjustedHeight = 0;
            NSInteger index = 0;
            for (NSDictionary* medium in [self media]) {
                if (index%2 == 0) {
                    //first image
                    currentAdjustedHeight = [medium height];
                    currentAggregateWidth = [medium width];
                } else if (index%2==1) {
                    //second image
                    currentAggregateWidth = currentAggregateWidth + [medium widthForHeight:currentAdjustedHeight];
                    currentAggregateWidth = currentAggregateWidth + 6.0f*(currentAggregateWidth/CONTENT_WIDTH);
                    imageHeight = imageHeight + currentAdjustedHeight*(CONTENT_WIDTH/currentAggregateWidth);
                }
                ++index;
            }
            imageHeight = imageHeight + 6.0f*([[self media] count]/2);
        } else {
            //THIS METHOD NOT FINISHED! NOT ADDING ON THE LAST GUY
            //two per row + three on last row
            imageHeight = 0;
            CGFloat currentAggregateWidth = 0;
            CGFloat currentAdjustedHeight = 0;
            NSInteger index = 0;
            for (NSDictionary* medium in [self media]) {
                if (index < [[self media] count]-3) {
                    if (index%2 == 0) {
                        //first image
                        currentAdjustedHeight = [medium height];
                        currentAggregateWidth = [medium width];
                    } else if (index%2==1) {
                        //second image
                        currentAggregateWidth = currentAggregateWidth + [medium widthForHeight:currentAdjustedHeight];
                        currentAggregateWidth = currentAggregateWidth + 6.0f*(currentAggregateWidth/CONTENT_WIDTH);
                        imageHeight = imageHeight + currentAdjustedHeight*(CONTENT_WIDTH/currentAggregateWidth);
                    }
                } else {
                    if (index%3 == 0) {
                        //first image
                        currentAdjustedHeight = [medium height];
                        currentAggregateWidth = [medium width];
                    } else if (index%3==1) {
                        //second image
                        currentAggregateWidth = currentAggregateWidth + [medium widthForHeight:currentAdjustedHeight];
                        //imageHeight = imageHeight + 10.0f + currentAdjustedHeight*(CONTENT_WIDTH/currentAggregateWidth);
                    } else if (index%3==2) {
                        //third image
                        currentAggregateWidth = currentAggregateWidth + [medium widthForHeight:currentAdjustedHeight];
                        currentAggregateWidth = currentAggregateWidth + 12.0f*(currentAggregateWidth/CONTENT_WIDTH);
                        imageHeight = imageHeight + currentAdjustedHeight*(CONTENT_WIDTH/currentAggregateWidth);
                    }
                }
                
                ++index;
            }
            imageHeight = imageHeight + 6.0f*([[self media] count]/2);
        }
    }
    
    return ceilf(messageHeight + imageHeight + THOUGHT_TOP_SIDE_MARGIN + THOUGHT_BOTTOM_SIDE_MARGIN);
}

@end
