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
        NSMutableArray* cropped = [[NSMutableArray alloc] initWithArray:[self mediaURLs]];
        int i = 0;
        for (NSString* edited in cropped) {
            [cropped replaceObjectAtIndex:i withObject:[edited stringByReplacingOccurrencesOfString:@"upload/" withString:[NSString stringWithFormat:@"upload/c_scale,w_%@/", [NSNumber numberWithInt:(int)[[UIScreen mainScreen] bounds].size.width]]]];
            ++i;
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
    return ([self message] && [[self message] length] > 0) ? [[self message] truncated:320] : @"";
}

- (NSString*) itemType
{
    return [self objectForKey:@"item_type"];
}

- (NSString*) reminderDate
{
    return [self objectForKey:@"reminder_date"];
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
    return [self message] && [[self message] length] > 0;
}

- (BOOL) hasReminder
{
    return [self reminderDate] && NULL_TO_NIL([self objectForKey:@"reminder_date"]);
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

@end
