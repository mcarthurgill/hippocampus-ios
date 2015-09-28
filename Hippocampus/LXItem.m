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
    [i setObject:@"outstanding" forKey:@"status"];
    return i;
}

+ (NSInteger) unassignedThoughtCount
{
    NSMutableDictionary* allThoughtBucket = [LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]];
    NSInteger count = 0;
    NSInteger index = 0;
    for (NSString* key in [allThoughtBucket itemKeys]) {
        NSMutableDictionary* object = [LXObjectManager objectWithLocalKey:key];
        if (object && [object isOutstanding]) {
            ++count;
        }
        ++index;
        if (index > 256) {
            return count;
        }
    }
    return count;
}

- (void) destroyItem
{
    if ([self belongsToCurrentUser]) {
        //remove from all items
        [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] removeItemFromBucket:self];
        //remove from each bucket
        for (NSMutableDictionary* bucket in [self bucketsArray]) {
            [[bucket mutableCopy] removeItemFromBucket:self];
        }
        [self destroyRemote];
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
    if ([[self objectType] isEqualToString:@"user"])
        return [NSString stringWithFormat:@"%@/avatar/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"APIRoot"], [self ID]];
    return [NSString stringWithFormat:@"%@/avatar/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"APIRoot"], [self userID]];
}

- (BOOL) hasAuthorName
{
    return [self objectForKey:@"user"] && [[self objectForKey:@"user"] objectForKey:@"name"] && NULL_TO_NIL([[self objectForKey:@"user"] objectForKey:@"name"]) && [[[self objectForKey:@"user"] objectForKey:@"name"] length] > 0;
}

- (NSString*) authorName
{
    return [[self objectForKey:@"user"] objectForKey:@"name"];
}

- (NSMutableArray*) bucketsArray
{
    NSMutableArray* temp = [[NSMutableArray alloc] init];
    if ([self objectForKey:@"buckets_array"] && [[self objectForKey:@"buckets_array"] count] > 0) {
        for (NSMutableDictionary* bucket in [self objectForKey:@"buckets_array"]) {
            if ([bucket hasAuthorizedUserID:[[[LXSession thisSession] user] ID]]) {
                [temp addObject:bucket];
            }
        }
    }
    return temp;
}


- (void) updateBucketsWithLocalKeys:(NSMutableArray*)newLocalKeys success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //OLD BUCKET KEYS
    NSMutableArray* oldBucketKeys = [[NSMutableArray alloc] init];
    if ([self bucketsArray]) {
        for (NSMutableDictionary* oldStub in [self bucketsArray]) {
            [oldBucketKeys addObject:[oldStub localKey]];
        }
    }
    //CREATE NEW BUCKETS ARRAY
    NSMutableArray* newBucketsArray = [[NSMutableArray alloc] init];
    NSMutableArray* unsavedNewBucketsArray = [[NSMutableArray alloc] init];
    for (NSString* key in newLocalKeys) {
        NSMutableDictionary* tempBucket = [LXObjectManager objectWithLocalKey:key];
        if (tempBucket) {
            [newBucketsArray addObject:tempBucket];
            //ADD TO BUCKET ON DISK
            if ([tempBucket itemKeys]) {
                //THE LINES BELOW WERE CAUSING A BUG OF REMOVING THE OTHER ITEM KEYS FROM THE BUCKET
//                NSMutableArray* tempItemKeys = [[tempBucket itemKeys] mutableCopy];
//                [tempItemKeys addObject:[self localKey]];
//                [tempBucket setObject:tempItemKeys forKey:@"item_keys"];
//                [tempBucket removeObjectForKey:@"updated_at"];
//                [tempBucket assignLocalVersionIfNeeded];
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":tempBucket}];
            } else {
                [tempBucket setObject:[@[[self localKey]] mutableCopy] forKey:@"item_keys"];
            }
            if (![tempBucket ID]) {
                [unsavedNewBucketsArray addObject:tempBucket];
            }
        }
        if ([oldBucketKeys containsObject:key]) {
            [oldBucketKeys removeObject:key];
        } else {
            //add to recent buckets
            [NSMutableDictionary addRecentBucketLocalKey:key];
        }
    }
    //REMOVE FROM THESE BUCKETS
    for (NSString* key in oldBucketKeys) {
        NSMutableDictionary* tempBucket = [LXObjectManager objectWithLocalKey:key];
        if (tempBucket && [tempBucket itemKeys]) {
            NSMutableArray* tempItemKeys = [[tempBucket itemKeys] mutableCopy];
            [tempItemKeys removeObject:[self localKey]];
            [tempBucket setObject:tempItemKeys forKey:@"item_keys"];
            [tempBucket removeObjectForKey:@"updated_at"];
            [tempBucket assignLocalVersionIfNeeded:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":tempBucket}];
        }
    }
    //SAVE THIS ITEM
    [self setObject:newBucketsArray forKey:@"buckets_array"];
    [self setObject:([newBucketsArray count] > 0 ? @"assigned" : @"outstanding") forKey:@"status"];
    [self removeObjectForKey:@"updated_at"];
    [LXObjectManager assignObject:self];
    //NSLog(@"item: %@", [LXObjectManager objectWithLocalKey:[self localKey]]);
    //SAVE UNSAVED BUCKETS FIRST
    if ([unsavedNewBucketsArray count] == 0) {
        //save now
        [self sendUpdateBucketsWithLocalKeys:newLocalKeys
                                     success:^(id responseObject){
                                         if (successCallback) {
                                             successCallback(responseObject);
                                         }
                                     }
                                     failure:^(NSError* error){
                                         if (failureCallback) {
                                             failureCallback(error);
                                         }
                                     }
         ];
    } else {
        __block NSInteger currentNumberSaved = 0;
        for (NSMutableDictionary* bucket in unsavedNewBucketsArray) {
            [bucket saveRemote:^(id responseObject){
                ++currentNumberSaved;
                if (currentNumberSaved == [unsavedNewBucketsArray count]) {
                    [NSMutableDictionary bucketKeysWithSuccess:nil failure:nil];
                    //save now
                    [self sendUpdateBucketsWithLocalKeys:newLocalKeys
                                                 success:^(id responseObject){
                                                     if (successCallback) {
                                                         successCallback(responseObject);
                                                     }
                                                 }
                                                 failure:^(NSError* error){
                                                     if (failureCallback) {
                                                         failureCallback(error);
                                                     }
                                                 }
                     ];
                }
            } failure:^(NSError* error){}];
        }
    }
    
}

- (void) sendUpdateBucketsWithLocalKeys:(NSMutableArray*)newLocalKeys success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //SEND TO SERVER
    [[LXServer shared] requestPath:@"/items/update_buckets" withMethod:@"PUT" withParamaters:@{@"local_key":[self localKey],@"local_keys":newLocalKeys} authType:@"user"
                           success:^(id responseObject) {
                               //SAVE LOCALLY
                               [LXObjectManager assignObject:responseObject];
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError* error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}


- (CGFloat) estimatedCellHeight
{
    CGFloat THOUGHT_LEFT_SIDE_MARGIN = 39.0f;
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

- (NSString*) reminderDescriptionString
{
    if (![self hasReminder]) {
        return @"No Nudge Set";
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSDate *d = [NSDate timeWithString:[self reminderDate]];
    if ([[[self itemType] lowercaseString] isEqualToString:@"once"]) {
        [formatter setDateFormat:@"MMMM d, yyyy"];
        return [formatter stringFromDate:d];
    } else if ([[[self itemType] lowercaseString] isEqualToString:@"yearly"]) {
        [formatter setDateFormat:@"MMMM d"];
        return [NSString stringWithFormat:@"Every %@", [formatter stringFromDate:d]];
    } else if ([[[self itemType] lowercaseString] isEqualToString:@"monthly"]) {
        [formatter setDateFormat:@"d"];
        return [NSString stringWithFormat:@"the %@ of every month", [formatter stringFromDate:d]];
    } else if ([[[self itemType] lowercaseString] isEqualToString:@"weekly"]) {
        [formatter setDateFormat:@"eeee"];
        return [NSString stringWithFormat:@"Every %@", [formatter stringFromDate:d]];
    } else if ([[[self itemType] lowercaseString] isEqualToString:@"daily"]) {
        return @"Every Day";
    }
    return [NSDate formattedDateFromString:[self reminderDate]];
}

- (NSMutableArray*) rawImages
{
    NSMutableArray* tempImages = [[NSMutableArray alloc] init];
    for (NSDictionary* medium in [self media]) {
        if ([SGImageCache haveImageForURL:[medium mediaThumbnailURLWithScreenWidth]]) {
            [tempImages addObject:[SGImageCache imageForURL:[medium mediaThumbnailURLWithScreenWidth]]];
        }
    }
    return tempImages;
}

- (BOOL) hasUnsavedMedia
{
    for (NSDictionary* medium in [self media]) {
        //NSLog(@"MEDIUM HERE: %@", medium);
        if ([medium objectForKey:@"local_file_name"] && !([medium objectForKey:@"url"] || [medium objectForKey:@"secure_url"])) {
            return YES;
        }
    }
    return NO;
}

- (void) saveMediaIfNecessary
{
    for (NSDictionary* medium in [self media]) {
        //NSLog(@"MEDIUM HERE: %@", medium);
        if ([medium objectForKey:@"local_file_name"] && !([medium objectForKey:@"url"] || [medium objectForKey:@"secure_url"])) {
            //save this image
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[medium objectForKey:@"local_file_name"]];
            NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
            [[LXServer shared] requestPath:@"/media.json" withMethod:@"POST" withParamaters:@{@"medium":medium}
                 constructingBodyWithBlock:^(id <AFMultipartFormData>formData){
                     [formData appendPartWithFileData:data name:@"file" fileName:@"temp.jpeg" mimeType:@"image/jpeg"];
                 }
                                   success:^(id responseObject) {
                                       NSError* error;
                                       NSFileManager *fileManager = [NSFileManager defaultManager];
                                       [fileManager removeItemAtPath:filePath error:&error];
                                       //update on disk
                                       [LXObjectManager assignObject:responseObject];
                                       //NSLog(@"form success: %@", responseObject);
                                   }
                                   failure:^(NSError* error){}
             ];
        }
    }
}

- (void) removeMediumWithLocalKey:(NSString*)mediumLocalKey
{
    NSMutableArray* tempMedia = [[NSMutableArray alloc] init];
    for (NSMutableDictionary* medium in [self media]) {
        if (![medium localKey] || ![[medium localKey] isEqualToString:mediumLocalKey]) {
            [tempMedia addObject:medium];
        } else {
            //delete
            [medium destroyRemote];
        }
    }
    [self setObject:tempMedia forKey:@"media_cache"];
    [LXObjectManager assignObject:self];
}


- (void) addEstimatedRowHeight:(CGFloat)height
{
    [self setObject:[NSNumber numberWithFloat:height] forKey:@"estimated_row_height"];
    [self assignLocalVersionIfNeeded:NO];
}


@end
