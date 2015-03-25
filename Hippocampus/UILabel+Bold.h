//
//  UILabel+Bold.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (Bold)

- (void) boldSubstring: (NSString*) substring;
- (void) boldRange: (NSRange) range;

@end
