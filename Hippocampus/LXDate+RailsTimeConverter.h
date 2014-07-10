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

@end
