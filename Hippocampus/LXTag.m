//
//  LXTag.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/29/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "LXTag.h"

@implementation NSMutableDictionary (LXTag)

- (NSString*) tagName
{
    return [self objectForKey:@"tag_name"] && NULL_TO_NIL([self objectForKey:@"tag_name"]) ? [self objectForKey:@"tag_name"] : @"";
}

@end
