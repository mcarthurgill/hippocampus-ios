//
//  NSArray+Alphabet.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/10/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "NSArray+Alphabet.h"

@implementation NSArray (Alphabet)

+ (NSArray*) alphabet
{
    return @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z"];
}

+ (NSArray*) alphabetUppercase
{
   return  @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
}

+ (NSArray*) alphabetLowercase
{
    return  @[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z"];
}

+ (NSArray*) alphabetUppercaseWithOther
{
    return  @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"#"];
}

+ (NSArray*) months
{
    return @[@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"];
}

+ (NSArray*) daysOfWeek
{
    return @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];
}

+ (NSArray*) daysOfWeekShort
{
    return @[@"Sun", @"Mon", @"Tue", @"Wed", @"Th", @"Fri", @"Sat"];
}

- (id) rand {
    if (self.count > 0) {
        id obj = [self objectAtIndex:arc4random_uniform((uint32_t)[self count])];
        if (obj) {
            return obj;
        }
    }
    return nil;
}

@end
