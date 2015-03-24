//
//  LXDate+RailsTimeConverter.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/9/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXDate+RailsTimeConverter.h"

@implementation NSDate (RailsTimeConverter)

+ (NSDate*) timeWithString:(NSString*)string
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZ"];
    NSDate* d = [dateFormat dateFromString:string];
    if (!d) {
        [dateFormat setDateFormat:@"yyyy-MM-dd"];
        return [dateFormat dateFromString:string];
    }
    return d;
}

+ (NSString*) formattedDateFromString:(NSString*)string
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *d = [formatter dateFromString:string];
    [formatter setDateFormat:@"EEE, dd MMM yyyy"];
    return [formatter stringFromDate:d];
}



+ (NSString*) timeAgoInWords:(double)relativeTimestamp
{
    double currentTimestamp = [[NSDate date] timeIntervalSince1970];
    double difference = currentTimestamp - relativeTimestamp;
    //difference = difference/1; //convert from ms to s
    if (difference < 90) {
        return @"about a minute ago";
    } else if (difference < 3600) {
        return [NSString stringWithFormat:@"%i minute%@ ago", (int)(difference+30)/60, ((int)(difference+30)/60 == 1 ? @"" : @"s")];
    } else if (difference < 86400) {
        return [NSString stringWithFormat:@"%i hour%@ ago", (int)(difference+1200)/3600, ((int)(difference+1200)/3600 == 1 ? @"" : @"s")];
    } else if (difference < 172800) {
        return [NSString stringWithFormat:@"yesterday"];
    } else {
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:relativeTimestamp];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MMMM d, yyyy"];
        return [dateFormat stringFromDate:date];
    }
    
    
//    if (difference < 2592000) {
//        return [NSString stringWithFormat:@"%i day%@ ago", (int)(difference+43200)/86400, ((int)(difference+43200)/86400 == 1 ? @"" : @"s")];
//    } else if (difference < 5184000) {
//        return [NSString stringWithFormat:@"last month"];
//    } else if (difference < 31536000) {
//        return [NSString stringWithFormat:@"%i month%@ ago", (int)(difference+43200)/2592000, ((int)(difference+43200)/2592000 == 1 ? @"" : @"s")];
//    } else {
//        return [NSString stringWithFormat:@"%i year%@ ago", (int)(difference+43200)/31449600, ((int)(difference+43200)/31449600 == 1 ? @"" : @"s")];
//    }
    return @"back when dinosaurs roamed the earth"; //31449600
}

+ (NSString*) timeAgoInWordsFromDatetime:(NSString*)string
{
    return [self timeAgoInWords:[[self timeWithString:string] timeIntervalSince1970]];
}

+ (NSString*) timeAgoActualFromDatetime:(NSString*)string
{
    NSDate* date = [self timeWithString:string];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MMMM d, yyyy"];
    return [dateFormat stringFromDate:date];
}

+ (NSInteger) currentYearInteger
{
   return [[NSDate date] yearInteger];
}

+ (NSInteger) currentMonthInteger
{
   return [[NSDate date] monthInteger];
}

+ (NSInteger) currentDayInteger
{
   return [[NSDate date] dayInteger];
}

- (NSInteger) yearInteger
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    
    return [components year];
}

- (NSInteger) monthInteger
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    
    return [components month];
}

- (NSInteger) dayInteger
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self];
    
    return [components day];
}

- (NSInteger) yearIndex
{
    NSLog(@"%i - %i", [self yearInteger], [NSDate currentYearInteger]);
    return [self yearInteger] < [NSDate currentYearInteger] ? 0 : ([self yearInteger] - [NSDate currentYearInteger]);
}

- (NSInteger) monthIndex
{
    return [self monthInteger]-1;
}

- (NSInteger) dayIndex
{
    return [self dayInteger]-1;
}

- (NSString*) dayOfWeek
{
    return [[NSArray daysOfWeek] objectAtIndex:[self dayOfWeekIndex]];
}

- (NSInteger) dayOfWeekIndex
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *weekdayComponents =[gregorian components:NSWeekdayCalendarUnit fromDate:self];
    return [weekdayComponents weekday]-1;
}


@end
