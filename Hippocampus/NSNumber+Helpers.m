//
//  NSNumber+Helpers.m
//  Hippocampus
//
//  Created by Will Schreiber on 4/1/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "NSNumber+Helpers.h"

@implementation NSNumber (Helpers)

- (NSString*) formattedString
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [formatter stringFromNumber:self];
}

- (NSString*) formattedPercentage
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    return [formatter stringFromNumber:[NSNumber numberWithFloat:[self floatValue]/100]];
}
@end
