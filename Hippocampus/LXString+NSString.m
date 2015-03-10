//
//  LXString+NSString.m
//  Hippocampus
//
//  Created by Will Schreiber on 1/21/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXString+NSString.h"

@implementation NSString (LXString)

- (NSString*) truncated:(int)length
{
    return length < [self length] ? [NSString stringWithFormat:@"%@ [...]", [self substringWithRange:NSMakeRange(0, length)]] : self;
}

+ (NSString *) randomCongratulations {
    NSArray *arr = [NSArray arrayWithObjects:@"Awesome Note!", @"Not going to forget that!", @"Way to go!", @"You're crushing it!", @"Nice memory!", @"You're getting smarter!", @"Great memory!", @"It's the details that matter", @"Memory game strong!", nil];
    return [arr objectAtIndex:arc4random_uniform((uint32_t)[arr count])];
}

@end
