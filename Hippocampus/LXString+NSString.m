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
    NSArray *arr = [NSArray arrayWithObjects:@"Awesome note.", @"Incredible.", @"You're crushing it.", @"Nice memory!", @"You're getting smarter.", @"Great memory!", @"Details matter.", @"Memory game strong!", @"Killing it.", @"Impressive.", nil];
    return [arr rand];
}

@end
