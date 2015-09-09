//
//  UIFont+HCFonts.m
//  Hippocampus
//
//  Created by Will Schreiber on 2/26/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIFont+HCFonts.h"

@implementation UIFont (HCFonts)

+ (UIFont*) noteDisplay
{
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
}

+ (UIFont*) explanationDisplay
{
    return [UIFont systemFontOfSize:17.0f];
}

+ (UIFont*) titleFont
{
    return [self titleFontWithSize:18.0f];
}

+ (UIFont*) titleFontWithSize:(NSInteger)size
{
    return [UIFont fontWithName:@"Roboto-Regular" size:size];
}

+ (UIFont*) titleLightFontWithSize:(NSInteger)size
{
    return [UIFont fontWithName:@"Roboto-Light" size:size];
}

+ (UIFont*) itemContentFont
{
    return [UIFont fontWithName:@"Roboto-Regular" size:14.0f];
}

+ (UIFont*) inputFont
{
    return [UIFont fontWithName:@"Roboto-Regular" size:16.0f];
}

+ (UIFont*) secondaryFontWithSize:(NSInteger)size
{
    return [UIFont fontWithName:@"Abel-Regular" size:size];
}

@end
