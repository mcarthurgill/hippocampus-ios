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

+ (int) daysInMonth:(NSString*)month
{
    NSDictionary* months = @{@"January":@31, @"February":@28, @"March":@31, @"April":@30, @"May":@31, @"June":@30, @"July":@31, @"August":@31, @"September":@30, @"October":@31, @"November":@30, @"December":@31};
    return [[months objectForKey:month] intValue];
}

+ (int) daysInMonthAtIndex:(int)index
{
    return [self daysInMonth:[[self months] objectAtIndex:index]];
}

+ (int) daysInMonthAtIndex:(int)index forYear:(int)year
{
    if (index == 1 && year%4==0) {
        return 29;
    }
    return [self daysInMonthAtIndex:index];
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


- (NSString *) namesOfContacts
{
    NSString *names = @"";
    for (NSDictionary *contact in self) {
        if (contact == self.lastObject && self.count > 1) {
            names = [names stringByAppendingString: self.count > 2 ? @"and " : @" and "];
        }
        names = [names stringByAppendingString:[contact name]];
        if (contact != self.lastObject && self.count > 2){
            names = [names stringByAppendingString:@", "];
        }
    }
    return names;
}

@end
