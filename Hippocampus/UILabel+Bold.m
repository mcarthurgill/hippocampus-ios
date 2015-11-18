//
//  UILabel+Bold.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UILabel+Bold.h"

@implementation UILabel (Bold)

- (void) boldRange: (NSRange) range {
    if (![self respondsToSelector:@selector(setAttributedText:)]) {
        return;
    }
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:self.text];
    [attributedText setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.font.pointSize]} range:range];
    
    self.attributedText = attributedText;
}

- (void) boldSubstring: (NSString*) substring {
    NSRange range = [self.text rangeOfString:substring];
    [self boldRange:range];
}

@end
