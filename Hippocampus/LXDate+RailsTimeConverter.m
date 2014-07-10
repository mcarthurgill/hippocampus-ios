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
    return [dateFormat dateFromString:string];
}


@end
