//
//  LXDate+RailsTimeConverter.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/9/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (RailsTimeConverter)

+ (NSDate*) timeWithString:(NSString*)string;

+ (NSString*) timeAgoInWords:(double)relativeTimestamp;

+ (NSString*) timeAgoInWordsFromDatetime:(NSString*)string;

+ (NSString*) timeAgoActualFromDatetime:(NSString*)string;

+ (NSString*) formattedDateFromString:(NSString*)string;

+ (NSInteger) currentYearInteger;
+ (NSInteger) currentMonthInteger;
+ (NSInteger) currentDayInteger;

- (NSInteger) yearInteger;
- (NSInteger) monthInteger;
- (NSInteger) dayInteger;

- (NSInteger) yearIndex;
- (NSInteger) monthIndex;
- (NSInteger) dayIndex;

- (NSString*) dayOfWeek;
- (NSInteger) dayOfWeekIndex;


@end
