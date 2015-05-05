//
//  UIImageView+Helpers.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 5/5/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIImageView+Helpers.h"

@implementation UIImageView (Helpers)

- (void) overlayPlayButton
{
    UIImageView *playButtonView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playButton.png"]];
    [playButtonView setTag:11];
    playButtonView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    [self addSubview:playButtonView];
}

- (void) removePlayButtonOverlay
{
    for (UIView *subview in [self subviews]) {
        if (subview.tag == 11) {
            [subview removeFromSuperview];
        }
    }
}
@end

