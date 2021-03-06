//
//  UIImage+Helpers.h
//  Hippocampus
//
//  Created by Will Schreiber on 4/1/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Helpers)

+ (UIImage*) thumbnailImageForVideo:(NSURL*)videoURL;

- (UIImage*) scaledToSize:(CGFloat)newHeight;

- (UIImage*) croppedImage:(CGRect)bounds;

- (UIImage*) resizeImageWithNewSize:(CGSize)newSize;

@end
