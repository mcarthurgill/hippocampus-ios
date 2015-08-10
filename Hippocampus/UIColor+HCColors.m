//
//  UIColor+HCColors.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIColor+HCColors.h"

@implementation UIColor (HCColors)

+ (UIColor*) mainColor
{
    return [UIColor colorWithRed:0.235f green:0.592f blue:0.867f alpha:1.0f];
}

+ (UIColor*) actionColor
{
    return [UIColor colorWithRed:0.490f green:0.765f blue:0.490f alpha:1.0f];
}

+ (UIColor*) navigationColor
{
    return [UIColor colorWithRed:0.235f green:0.592f blue:0.867f alpha:1.0f];
}

+ (UIColor*) inactiveColor
{
    return [UIColor colorWithRed:0.757f green:0.780f blue:0.788f alpha:1.0f];
}

@end