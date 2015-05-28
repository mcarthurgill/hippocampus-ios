//
//  NSDictionary+Attributes.m
//  Hippocampus
//
//  Created by Will Schreiber on 2/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "NSDictionary+Attributes.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation NSDictionary (Attributes)


# pragma mark attribute helpers

- (NSString*) ID
{
    return [self objectForKey:@"id"];
}

- (NSString*) itemID
{
    return [self objectForKey:@"item_id"];
}

- (NSString*) bucketID
{
    return [self objectForKey:@"bucket_id"];
}

- (NSString*) userID
{
    return [self objectForKey:@"user_id"];
}

- (NSString*) groupID
{
    return NULL_TO_NIL([self objectForKey:@"group_id"]);
}

- (NSString*) getGroupID
{
    if (NULL_TO_NIL([self objectForKey:@"group"]) && [[self objectForKey:@"group"] ID]) {
        return [[self objectForKey:@"group"] ID];
    }
    if ([self bucketUserPairs] && [[self bucketUserPairs] respondsToSelector:@selector(count)]) {
        for (NSDictionary* bup in [self bucketUserPairs]) {
            if ([[bup phoneNumber] isEqualToString:[[[LXSession thisSession] user] phone]]) {
                return [bup groupID];
            }
        }
    }
    if ([[LXSession thisSession] groups]) {
        for (NSDictionary* group in [[LXSession thisSession] groups]) {
            if ([group objectForKey:@"sorted_buckets"]) {
                for (NSDictionary* bucket in [group objectForKey:@"sorted_buckets"]) {
                    if ([[bucket ID] isEqual:[self ID]]) {
                        return [group ID];
                    }
                }
            }
        }
    }
    return nil;
}

- (NSString*) groupName
{
    return NULL_TO_NIL([self objectForKey:@"group_name"]);
}

- (NSString*) getGroupName
{
    if (NULL_TO_NIL([self objectForKey:@"group"]) && [[self objectForKey:@"group"] groupName]) {
        return [[self objectForKey:@"group"] groupName];
    }
    return @"Ungrouped";
}

- (NSString*) phoneNumber
{
    return NULL_TO_NIL([self objectForKey:@"phone_number"]);
}

- (BOOL) belongsToCurrentUser
{
    return [[NSString stringWithFormat:@"%@", [self userID]] isEqualToString:[[HCUser loggedInUser] userID]];
}

- (NSString*) createdAt
{
    if ([self objectForKey:@"created_at_server"])
        return [self objectForKey:@"created_at_server"];
    return [self objectForKey:@"created_at"];
}

- (NSString*) updatedAt
{
    if ([self objectForKey:@"updated_at_server"])
        return [self objectForKey:@"updated_at_server"];
    return [self objectForKey:@"updated_at"];
}

- (NSMutableArray*) buckets
{
    if ([self objectForKey:@"buckets"] && [[self objectForKey:@"buckets"] respondsToSelector:@selector(count)])
        return [[NSMutableArray alloc] initWithArray:[self objectForKey:@"buckets"]];
    return nil;
}

- (NSString*) bucketsString
{
    return [self objectForKey:@"buckets_string"];
}

- (NSString*) deviceTimestamp
{
    return [self objectForKey:@"device_timestamp"];
}

- (NSMutableArray*) mediaURLs
{
    if ([self objectForKey:@"media_urls"] && [[self objectForKey:@"media_urls"] respondsToSelector:@selector(count)])
        return [[NSMutableArray alloc] initWithArray:[self objectForKey:@"media_urls"]];
    return nil;
}

- (NSMutableArray*) croppedMediaURLs
{
    if ([self mediaURLs]) {
        NSMutableArray* cropped = [[NSMutableArray alloc] init];
        int i = 0;
        for (NSString* edited in [self mediaURLs]) {
            if ([edited isImageUrl]) {
                [cropped addObject:[edited croppedImageURLToScreenWidth]];
                ++i;
            }
        }
        return cropped;
    }
    return nil;
}

- (NSString*) message
{
    return [self objectForKey:@"message"];
}

- (NSString*) truncatedMessage
{
    return ([self message] && NULL_TO_NIL([self message]) && [[self message] length] > 0) ? [[self message] truncated:320] : @"";
}

- (NSString*) itemType
{
    return [self objectForKey:@"item_type"];
}

- (NSString*) name
{
    return [self objectForKey:@"name"];
}

- (NSString*) reminderDate
{
    return [self objectForKey:@"reminder_date"];
}

- (NSString*) nextReminderDate
{
    return [self objectForKey:@"next_reminder_date"];
}

- (NSString*) status
{
    return [self objectForKey:@"status"];
}

- (NSString*) inputMethod
{
    return [self objectForKey:@"input_method"];
}

- (NSString*) description
{
    return [self objectForKey:@"description"];
}

- (NSString*) firstName
{
    return [self objectForKey:@"first_name"];
}

- (NSString*) itemsCount
{
    return [self objectForKey:@"items_count"];
}

- (NSString*) bucketType
{
    return [self objectForKey:@"bucket_type"];
}

- (NSString*) visibility
{
    return [self objectForKey:@"visibility"];
}

- (NSString*) unseenItems
{
    return [self objectForKey:@"unseen_items"];
}

- (NSString*) itemUserName
{
    if (![self hasItemUserName])
        return nil;
    return [[self objectForKey:@"user"] objectForKey:@"name"];
}

- (NSArray*) bucketUserPairs
{
    return [self objectForKey:@"bucket_user_pairs"];
}

- (CLLocation*) location
{
    if ([self hasLocation]) {
        return [[CLLocation alloc] initWithLatitude:[[self objectForKey:@"latitude"] doubleValue] longitude:[[self objectForKey:@"longitude"] doubleValue]];
    }
    return nil;
}

- (BOOL) hasID
{
    return [self objectForKey:@"id"] && NULL_TO_NIL([self objectForKey:@"id"]);
}

- (BOOL) isAllNotesBucket
{
    return ![self ID] || !NULL_TO_NIL([self objectForKey:@"id"]) || ( [self ID] && [[self ID] integerValue] == 0 );
}

- (BOOL) hasItems
{
    return [self itemsCount] && [[self itemsCount] integerValue] > 0;
}

- (BOOL) hasBucketsString
{
    return [self bucketsString] && NULL_TO_NIL([self objectForKey:@"buckets_string"]);
}

- (BOOL) hasLocation
{
    return [self objectForKey:@"latitude"] && NULL_TO_NIL([self objectForKey:@"latitude"]) && [self objectForKey:@"longitude"] && NULL_TO_NIL([self objectForKey:@"longitude"]);
}

- (BOOL) isOutstanding
{
    return [self status] && [[self status] isEqualToString:@"outstanding"];
}

- (BOOL) hasMediaURLs
{
    return [self mediaURLs] && [[self mediaURLs] count] > 0;
}

- (BOOL) hasMessage
{
    return [self message] && NULL_TO_NIL([self message]) && [[self message] length] > 0;
}

- (BOOL) hasReminder
{
    return [self reminderDate] && NULL_TO_NIL([self objectForKey:@"reminder_date"]);
}

- (BOOL) hasNextReminderDate
{
    return [self nextReminderDate] && NULL_TO_NIL([self objectForKey:@"next_reminder_date"]);
}

- (BOOL) hasItemType
{
    return [self itemType] && NULL_TO_NIL([self objectForKey:@"item_type"]);
}

- (BOOL) hasBuckets
{
    return [self buckets] && [[self buckets] count] > 0;
}

- (BOOL) equalsObjectBasedOnTimestamp:(NSDictionary*)other
{
    return [self deviceTimestamp] && [[self deviceTimestamp] respondsToSelector:@selector(isEqualToString:)] && [[self deviceTimestamp] isEqualToString:[other deviceTimestamp]];
}

- (NSString*) firstWord
{
    return [[[self message] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
}

- (BOOL) messageIsOneWord
{
    return [[self message] length] < 100 && [[[self message] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] count] == 1;
}

- (BOOL) notBlank
{
    return [self message] && [[self message] length] > 0;
}

- (BOOL) lettersOnly
{
    NSCharacterSet *strCharSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    strCharSet = [strCharSet invertedSet];
    
    NSRange r = [[self message] rangeOfCharacterFromSet:strCharSet];
    return !(r.location != NSNotFound);
}

- (BOOL) onceReminder
{
    return [[self itemType] isEqualToString:@"once"];
}

- (BOOL) yearlyReminder
{
    return [[self itemType] isEqualToString:@"yearly"];
}

- (BOOL) monthlyReminder
{
    return [[self itemType] isEqualToString:@"monthly"];
}

- (BOOL) weeklyReminder
{
    return [[self itemType] isEqualToString:@"weekly"];
}

- (BOOL) dailyReminder
{
    return [[self itemType] isEqualToString:@"daily"];
}

- (BOOL) hasCollaborators
{
    return [self bucketUserPairs] && [[self bucketUserPairs] count] > 1;
}

- (BOOL) isCollaborativeThread
{
    return [self visibility] && [[self visibility] isEqualToString:@"collaborative"];
}

- (BOOL) hasUnseenItems
{
    return [self unseenItems] && [[self unseenItems] isEqualToString:@"yes"];
}

- (BOOL) hasCollaborativeThread
{
    if (![self hasBuckets])
        return NO;
    NSArray* bucketsCopy = [[NSArray alloc] initWithArray:[self buckets]];
    if (!bucketsCopy)
        return NO;
    for (int i = 0; i < [bucketsCopy count]; ++i) {
        if ([[bucketsCopy objectAtIndex:i] isCollaborativeThread])
            return YES;
    }
    return NO;
}

- (NSDictionary*) creator
{
    return [self objectForKey:@"creator"];
}

- (NSArray*) contactCards
{
    return [self objectForKey:@"contact_cards"];
}

- (NSDictionary*) contactCard
{
    if ([self objectForKey:@"contact_cards"]) {
        return [[self objectForKey:@"contact_cards"] firstObject];
    }
    return nil;
}

- (NSArray*) phones
{
    return [self objectForKey:@"phones"];
}

- (NSString*) firstPhone
{
    return [[self objectForKey:@"phones"] firstObject];
}

- (NSArray*) emails
{
    return [self objectForKey:@"emails"];
}

- (NSString*) lastName
{
    return [self objectForKey:@"last_name"];
}

- (NSNumber*) recordID
{
    return [self objectForKey:@"recordID"];
}

- (NSString*) note
{
    return [self objectForKey:@"note"];
}

- (NSString*) birthday
{
    return [self objectForKey:@"birthday"];
}

- (NSString*) company
{
    return [self objectForKey:@"company"];
}

- (BOOL) hasContacts
{
    return [self objectForKey:@"contact_cards"] && [[self objectForKey:@"contact_cards"] count] > 0;
}

- (BOOL) hasItemUserName
{
    return [self objectForKey:@"user"] && [[self objectForKey:@"user"] respondsToSelector:@selector(objectForKey:)] && NULL_TO_NIL([[self objectForKey:@"user"] objectForKey:@"name"]);
}


- (int)indexOfMatchingVideoUrl:(NSString*)imageURL
{
    NSString *imagePublicID = [imageURL cloudinaryPublicID];
    for (NSString*url in [self mediaURLs]) {
        if ([url containsString:imagePublicID] && !([[imageURL fileExtension] isEqualToString:[url fileExtension]])) {
            return (int)[[self mediaURLs] indexOfObject:url];
        }
    }
    return -1;
}


# pragma mark other dictionary helpers

- (NSMutableDictionary*) cleanDictionary
{
    NSMutableDictionary* tDict = [[NSMutableDictionary alloc] initWithDictionary:self];
    NSArray* keys = [tDict allKeys];
    for (NSString* k in keys) {
        if (!NULL_TO_NIL([tDict objectForKey:k])) {
            [tDict removeObjectForKey:k];
        }
        if ([[tDict objectForKey:k] isKindOfClass:[NSString class]]) {
            if (!NULL_TO_NIL([tDict objectForKey:k])) {
                [tDict removeObjectForKey:k];
            }
        } else if ([[tDict objectForKey:k] isKindOfClass:[NSArray class]] && [[tDict objectForKey:k] count] == 0) {
            [tDict removeObjectForKey:k];
        } else if ([[tDict objectForKey:k] isKindOfClass:[NSArray class]] || [[tDict objectForKey:k] isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray* temporaryInnerArray = [[NSMutableArray alloc] init];
            for (id object in [tDict objectForKey:k]) {
                if ([object isKindOfClass:[NSString class]]) {
                    [temporaryInnerArray addObject:object];
                } else {
                    [temporaryInnerArray addObject:[object cleanDictionary]];
                }
            }
            [tDict setObject:temporaryInnerArray forKey:k];
        } else if ([[tDict objectForKey:k] isKindOfClass:[NSDictionary class]] || [[tDict objectForKey:k] isKindOfClass:[NSMutableDictionary class]]) {
            return [[tDict objectForKey:k] cleanDictionary];
        }
    }
    return tDict;
}

- (NSMutableDictionary*) bucketNames
{
    NSMutableDictionary *bucketNamesDict = [[NSMutableDictionary alloc] init];
    //for (NSDictionary*bucketType in self) {
    for (NSDictionary*bucket in [self objectForKey:@"Recent"]) {
        [bucketNamesDict setObject:@"" forKey:[bucket firstName]];
    }
    for (int i = 0; i < [[self objectForKey:@"groups"] count]; ++i) {
        for (NSDictionary*bucket in [[[self objectForKey:@"groups"] objectAtIndex:i] objectForKey:@"sorted_buckets"]) {
            if ([bucket firstName]) {
                [bucketNamesDict setObject:@"" forKey:[bucket firstName]];
            }
        }
    }
    for (NSDictionary*bucket in [self objectForKey:@"buckets"]) {
        [bucketNamesDict setObject:@"" forKey:[bucket firstName]];
    }
    //}
    return bucketNamesDict;
}

- (NSArray*) groups
{
    return [self objectForKey:@"groups"];
}


# pragma mark actions

- (void) deleteItemWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [self ID]] withMethod:@"DELETE" withParamaters:nil
                           success:^(id responseObject) {
                               [[LXServer shared] getAllItemsWithPage:0 success:nil failure:nil];
                               if ([self hasBuckets]) {
                                   for (NSDictionary* bucket in [self buckets]) {
                                       [[LXServer shared] getBucketShowWithPage:0 bucketID:[bucket ID] success:nil failure:nil];
                                   }
                               }
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

@end
