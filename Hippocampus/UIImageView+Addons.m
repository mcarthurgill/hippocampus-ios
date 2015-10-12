//
//  UIImageView+Addons.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/15/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIImageView+Addons.h"
#import <objc/runtime.h>

#define IMAGE_FADE_IN_TIME 0.4f

@implementation UIImageView (Addons)

@dynamic remoteURLString;

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
    //self.image = nil;
    [self setRemoteURLString:remoteURL];
    
    if ([SGImageCache haveImageForURL:remoteURL]) {
        [self drawImageAsync:[SGImageCache imageForURL:remoteURL]];
        [self setAlpha:1.0f];
        [self viewWithTag:1].alpha = 0.0;
        [[self viewWithTag:1] removeFromSuperview];
    } else if (![self.image isEqual:[SGImageCache imageForURL:remoteURL]]) {
        //self.image = nil;
        if (localURL) {
            NSLog(@"localURL: %@", localURL);
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:localURL];
            if ([UIImage imageWithContentsOfFile:filePath]) {
                [self drawImageAsync:[UIImage imageWithContentsOfFile:filePath]];
            } else {
                self.image = nil;
            }
        } else {
            self.image = nil;
        }
        [self setAlpha:1.0f];
        [SGImageCache getImageForURL:remoteURL].then(^(UIImage* img) {
            if ([remoteURL isEqualToString:self.remoteURLString]) {
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
            }
        });
    }
}


- (void) setRemoteURLString:(NSString*) remoteURLString
{
    objc_setAssociatedObject(self, @selector(remoteURLString), remoteURLString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSString*) remoteURLString
{
    return objc_getAssociatedObject(self, @selector(remoteURLString));
}

@end
