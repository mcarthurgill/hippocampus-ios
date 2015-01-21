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
    return [self substringWithRange:NSMakeRange(0, MIN([self length], length))];
}

@end
