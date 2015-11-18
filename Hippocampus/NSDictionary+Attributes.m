//
//  NSDictionary+Attributes.m
//  Hippocampus
//
//  Created by Will Schreiber on 2/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "NSDictionary+Attributes.h"
#import "NSArray+Attributes.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation NSDictionary (Attributes)


# pragma mark attribute helpers


//NEW

- (NSString*) mediaURL
{
    return [self objectForKey:@"media_url"];
}

- (NSString*) mediaThumbnailURLWithScreenWidth
{
    return [self mediaThumbnailURLWithWidth:([[UIScreen mainScreen] scale]*[[UIScreen mainScreen] bounds].size.width)];
}

- (NSString*) mediaThumbnailURLWithWidth:(NSInteger)width
{
    CGFloat max_dimension = 4999.0/([[UIScreen mainScreen] scale]);
    if (!width)
        return [[self mediaThumbnailURL] croppedImageURLToScreenWidth];
    if (width > max_dimension && [self width] > [self height])
        width = max_dimension;
    if ([self height] > [self width] && [self heightForWidth:width] > max_dimension)
        width = [self widthForHeight:max_dimension];
    return [[self mediaThumbnailURL] croppedImageURLToWidth:width];
}

- (NSString*) mediaThumbnailURL
{
    return [self objectForKey:@"thumbnail_url"] && NULL_TO_NIL([self objectForKey:@"thumbnail_url"]) ? [self objectForKey:@"thumbnail_url"] : [self mediaURL];
}

- (CGFloat) width
{
    //NSLog(@"width: %f", [self objectForKey:@"width"] && NULL_TO_NIL([self objectForKey:@"width"]) ? [[self objectForKey:@"width"] floatValue] : 0.0f);
    return [self objectForKey:@"width"] && NULL_TO_NIL([self objectForKey:@"width"]) ? [[self objectForKey:@"width"] floatValue] : 0.0f;
}

- (CGFloat) height
{
    //NSLog(@"height: %f", [self objectForKey:@"height"] && NULL_TO_NIL([self objectForKey:@"height"]) ? [[self objectForKey:@"height"] floatValue] : 0.0f);
    return [self objectForKey:@"height"] && NULL_TO_NIL([self objectForKey:@"height"]) ? [[self objectForKey:@"height"] floatValue] : 0.0f;
}

- (CGFloat) mediaSizeRatio
{
    //NSLog(@"sizeRatio: %f", [self width]/[self height]);
    if ([self height] > 0.0)
        return [self width]/[self height];
    return 0.0f;
}

- (CGFloat) widthForHeight:(CGFloat)height
{
    //NSLog(@"widthForHeight: %f", [self mediaSizeRatio]*height);
    return [self mediaSizeRatio]*height;
}

- (CGFloat) heightForWidth:(CGFloat)width
{
    //NSLog(@"widthForHeight: %f", [self mediaSizeRatio]*height);
    if ([self mediaSizeRatio]*width>0.0)
        return 1.0f/[self mediaSizeRatio]*width;
    return 0.0f;
}

- (CGSize) sizeWithNewWidth:(CGFloat)width
{
    return CGSizeMake(width, [self heightForWidth:width]);
}

- (NSString*) avatarURLStringFromPhone
{
    return [NSString stringWithFormat:@"%@/avatar/%@/phone", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"APIRoot"], [self phoneNumber]];
}

- (BOOL) isVideo
{
    return [self objectForKey:@"media_type"] && [[self objectForKey:@"media_type"] isEqualToString:@"video"];
}

- (BOOL) isAudio
{
    return [self objectForKey:@"media_type"] && [[self objectForKey:@"media_type"] isEqualToString:@"audio"];
}

- (NSArray*) userIDsArray
{
    if ([self objectForKey:@"user_ids_array"] && NULL_TO_NIL([self objectForKey:@"user_ids_array"])) {
        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for (id num in [self objectForKey:@"user_ids_array"]) {
            [temp addObject:[NSString stringWithFormat:@"%@", num]];
        }
        return temp;
    }
    return @[];
}

- (NSArray*) authorizedUserIDs
{
    if ([self objectForKey:@"authorized_user_ids"] && NULL_TO_NIL([self objectForKey:@"authorized_user_ids"])) {
        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for (id num in [self objectForKey:@"authorized_user_ids"]) {
            [temp addObject:[NSString stringWithFormat:@"%@", num]];
        }
        return temp;
    }
    return @[];
}

- (BOOL) authorizedToSee
{
    if ([[self objectType] isEqualToString:@"item"]) {
        return [[self userIDsArray] containsObject:[NSString stringWithFormat:@"%@", [[[LXSession thisSession] user] ID]]] || [self belongsToCurrentUser];
    } else if ([[self objectType] isEqualToString:@"bucket"]) {
        return [[self authorizedUserIDs] containsObject:[NSString stringWithFormat:@"%@", [[[LXSession thisSession] user] ID]]] || [self belongsToCurrentUser];
    }
    return YES;
}


//OLD

- (NSString*) ID
{
    return [self objectForKey:@"id"];
}

- (NSString*) objectType
{
    return [self objectForKey:@"object_type"];
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
    return [[NSString stringWithFormat:@"%@", [self userID]] isEqualToString:[NSString stringWithFormat:@"%@", [[[LXSession thisSession] user] ID]]];
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
    return [self objectForKey:@"buckets"] && [[self objectForKey:@"buckets"] respondsToSelector:@selector(count)] ? [[NSMutableArray alloc] initWithArray:[self objectForKey:@"buckets"]] : nil;
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
    return [self objectForKey:@"message"] && NULL_TO_NIL([self objectForKey:@"message"]) ? [[[self objectForKey:@"message"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\uFFFC"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : nil;
}

- (NSString*) truncatedMessage
{
    return ([self message] && [[self message] length] > 0) ? [[self message] truncated:320] : @"";
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

- (NSString*) audioURL
{
    if ([self objectForKey:@"audio_url"] && NULL_TO_NIL([self objectForKey:@"audio_url"]) && [[self objectForKey:@"audio_url"] length] > 5) {
        NSString* stringURL = [self objectForKey:@"audio_url"];
        NSURL *url = [NSURL URLWithString:stringURL];
        NSString *path = [url path];
        NSString *extension = [path pathExtension];
        //NSLog(@"extension: %@", extension);
        return !extension || [extension length] == 0 ? [NSString stringWithFormat:@"%@.mp3", stringURL] : stringURL;
    }
    return nil;
}

- (NSString*) inputMethod
{
    return [self objectForKey:@"input_method"];
}

- (NSString*) description
{
    return [self objectForKey:@"description"] && NULL_TO_NIL([self objectForKey:@"description"]) ? [[[self objectForKey:@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\uFFFC"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : nil;
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

- (NSArray*) links
{
    return [self objectForKey:@"links"] && [[self objectForKey:@"links"] respondsToSelector:@selector(count)] ? [self objectForKey:@"links"] : @[];
}

- (CLLocation*) location
{
    if ([self hasLocation]) {
        return [[CLLocation alloc] initWithLatitude:[[self objectForKey:@"latitude"] doubleValue] longitude:[[self objectForKey:@"longitude"] doubleValue]];
    }
    return nil;
}

- (NSString*) latitude
{
    if ([self objectForKey:@"latitude"] && NULL_TO_NIL([self objectForKey:@"latitude"])) {
        return [NSString stringWithFormat:@"%@", [self objectForKey:@"latitude"]];
    }
    return nil;
}
- (NSString*) longitude
{
    if ([self objectForKey:@"longitude"] && NULL_TO_NIL([self objectForKey:@"longitude"])) {
        return [NSString stringWithFormat:@"%@", [self objectForKey:@"longitude"]];
    }
    return nil;
}
- (NSString*) latLongKey
{
    if ([self latitude] && [self longitude]) {
        return [NSString stringWithFormat:@"%@,%@", [self latitude], [self longitude]];
    }
    return @"no-key";
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
    return (![self status] && ![self hasBuckets]) || [[self status] isEqualToString:@"outstanding"];
}

- (BOOL) hasMessage
{
    return [self message] && [[self message] length] > 0;
}

- (BOOL) hasReminder
{
    return [self reminderDate] && NULL_TO_NIL([self objectForKey:@"reminder_date"]);
}

- (BOOL) hasNextReminderDate
{
    return [self nextReminderDate] && NULL_TO_NIL([self objectForKey:@"next_reminder_date"]);
}

- (BOOL) hasAudioURL
{
    return [self objectForKey:@"audio_url"] && [self audioURL];
}

- (BOOL) hasItemType
{
    return [self itemType] && NULL_TO_NIL([self objectForKey:@"item_type"]);
}

- (BOOL) hasBuckets
{
    return [self objectForKey:@"buckets_array"] && [[self objectForKey:@"buckets_array"] count] > 0;
}

- (BOOL) hasLinks
{
    return [self links] && [[self links] count] > 0;
}

- (BOOL) messageIsOnlyLinks
{
    if (![self hasLinks] || ![self hasMessage])
        return NO;
    NSArray *wordsInMessages = [[[self message] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
    for (NSString* potentialLink in wordsInMessages) {
        if (![[self links] containsObject:potentialLink])
            return NO;
    }
    return YES;
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
    NSMutableDictionary* tDict = [[NSMutableDictionary alloc] init];
    
    NSArray* keys = [self allKeys];
    
    for (NSString* k in keys) {
        
        if (NULL_TO_NIL([self objectForKey:k])) {
            if ([[self objectForKey:k] isKindOfClass:[NSArray class]] || [[self objectForKey:k] isKindOfClass:[NSMutableArray class]]) {
                NSMutableArray* temporaryInnerArray = [[self objectForKey:k] cleanArray];
                if (temporaryInnerArray) {
                    [tDict setObject:temporaryInnerArray forKey:k];
                }
                
            } else if ([[self objectForKey:k] isKindOfClass:[NSDictionary class]] || [[self objectForKey:k] isKindOfClass:[NSMutableDictionary class]]) {
                NSMutableDictionary* temp = [[self objectForKey:k] cleanDictionary];
                if (temp) {
                    [tDict setObject:temp forKey:k];
                }
            
            } else if ([[self objectForKey:k] isKindOfClass:[NSString class]] || [[self objectForKey:k] isKindOfClass:[NSNumber class]]) {
                if (NULL_TO_NIL([self objectForKey:k])) {
                    [tDict setObject:[self objectForKey:k] forKey:k];
                }
                
            }
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



@end
