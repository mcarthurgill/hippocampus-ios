//
//  UIFont+HCFonts.h
//  Hippocampus
//
//  Created by Will Schreiber on 2/26/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (HCFonts)

+ (UIFont*) noteDisplay;
+ (UIFont*) explanationDisplay;

+ (UIFont*) titleFont;
+ (UIFont*) titleFontWithSize:(NSInteger)size;
+ (UIFont*) itemContentFont;
+ (UIFont*) inputFont;

@end
