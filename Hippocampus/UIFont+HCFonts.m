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

@end
