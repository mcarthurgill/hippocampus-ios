//
//  NSArray+Alphabet.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/10/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Alphabet)

+ (NSArray*) alphabet;

+ (NSArray*) alphabetUppercase;

+ (NSArray*) alphabetLowercase;

+ (NSArray*) alphabetUppercaseWithOther;

+ (NSArray*) months;

+ (NSArray*) daysOfWeek;

+ (NSArray*) daysOfWeekShort;

- (id) rand;

- (NSString *) namesOfContacts;

@end
