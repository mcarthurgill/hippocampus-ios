//
//  LXLink.m
//  Hippocampus
//
//  Created by Will Schreiber on 11/4/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "LXLink.h"

@implementation NSMutableDictionary (LXLink)

- (NSString*) bestImage
{
    return [self objectForKey:@"best_image"] && NULL_TO_NIL([self objectForKey:@"best_image"]) && [[self objectForKey:@"best_image"] length] > 0 ? [self objectForKey:@"best_image"] : nil;
}

- (NSString*) bestTitle
{
    return [self objectForKey:@"best_title"] && NULL_TO_NIL([self objectForKey:@"best_title"]) ? [self objectForKey:@"best_title"] : nil;
}

- (NSString*) URLString
{
    return [self objectForKey:@"url"] && NULL_TO_NIL([self objectForKey:@"url"]) ? [self objectForKey:@"url"] : nil;
}

- (NSString*) bestDescription
{
    return [self objectForKey:@"description"] && NULL_TO_NIL([self objectForKey:@"description"]) ? [self objectForKey:@"description"] : nil;
}

@end
