//
//  UIImageView+Addons.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/15/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIImageView+Addons.h"
#define IMAGE_FADE_IN_TIME 0.4f

@implementation UIImageView (Addons)

- (void) drawImageAsync:(UIImage *)img
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        // Make a trivial (1x1) graphics context, and draw the image into it
//        UIGraphicsBeginImageContext(CGSizeMake(1,1));
//        CGContextRef context = UIGraphicsGetCurrentContext();
//        CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), [img CGImage]);
//        UIGraphicsEndImageContext();
        // Now the image will have been loaded and decoded and is ready to rock for the main thread
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setImage:img];
        });
    });
}

- (void) loadInImageWithRemoteURL:(NSString*)remoteURL localURL:(NSString*)localURL
{
    self.image = nil;
    
    if ([SGImageCache haveImageForURL:remoteURL]) {
        [self drawImageAsync:[SGImageCache imageForURL:remoteURL]];
        [self setAlpha:1.0f];
        [self viewWithTag:1].alpha = 0.0;
        [[self viewWithTag:1] removeFromSuperview];
    } else if (![self.image isEqual:[SGImageCache imageForURL:remoteURL]]) {
        self.image = nil;
        if (localURL && [UIImage imageWithContentsOfFile:localURL]) {
            [self drawImageAsync:[UIImage imageWithContentsOfFile:localURL]];
        }
        [self setAlpha:1.0f];
        [SGImageCache getImageForURL:remoteURL].then(^(UIImage* img) {
            if (img) {
                float curAlpha = [self alpha];
                [self setAlpha:0.0f];
                [self drawImageAsync:img];
                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void){
                    [self setAlpha:curAlpha];
                    [self viewWithTag:1].alpha = 0.0;
                    [[self viewWithTag:1] removeFromSuperview];
                }];
            }
        });
    }
}

@end