//
//  LXUser.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXUser.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation NSMutableDictionary (User)

- (void) makeLoggedInUser
{
    [self saveLocal];
    [[NSUserDefaults standardUserDefaults] setObject:[self localKey] forKey:@"localUserKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) updateTimeZone
{
    NSLog(@"timeZone: %@", [[NSTimeZone localTimeZone] name]);
    [self setObject:[[NSTimeZone localTimeZone] name] forKey:@"time_zone"];
    [self sync];
}


- (NSString*) email
{
    if (NULL_TO_NIL([self objectForKey:@"email"]))
        return [self objectForKey:@"email"];
    return nil;
}

- (NSString*) phone
{
    if (NULL_TO_NIL([self objectForKey:@"phone"]))
        return [self objectForKey:@"phone"];
    return nil;
}

- (NSString*) salt
{
    if (NULL_TO_NIL([self objectForKey:@"salt"]))
        return [self objectForKey:@"salt"];
    return nil;
}

- (NSNumber*) score
{
    if (NULL_TO_NIL([self objectForKey:@"score"]))
        return [self objectForKey:@"score"];
    return nil;
}

- (NSNumber*) numberItems
{
    if (NULL_TO_NIL([self objectForKey:@"number_items"]))
        return [self objectForKey:@"number_items"];
    return nil;
}

- (NSNumber*) numberBuckets
{
    if (NULL_TO_NIL([self objectForKey:@"number_buckets"]))
        return [self objectForKey:@"number_buckets"];
    return nil;
}

- (NSNumber*) setupCompletion
{
    if (NULL_TO_NIL([self objectForKey:@"setupCompletion"]))
        return [self objectForKey:@"setupCompletion"];
    return nil;
}

- (BOOL) completedSetup
{
    return [self.setupCompletion integerValue] == 100;
}

@end
