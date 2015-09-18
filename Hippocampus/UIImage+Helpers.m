//
//  UIImage+Helpers.m
//  Hippocampus
//
//  Created by Will Schreiber on 4/1/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIImage+Helpers.h"

@implementation UIImage (Helpers)

- (UIImage*) scaledToSize:(CGFloat)newHeight
{
    CGFloat currentHeight = self.size.height;
    CGFloat newWidth = self.size.width*(newHeight/currentHeight);
    UIGraphicsBeginImageContext( CGSizeMake(newWidth, newHeight) );
    [self drawInRect:CGRectMake(0,0,newWidth,newHeight)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*) croppedImage:(CGRect)bounds
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], bounds);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

- (UIImage*) resizeImageWithNewSize:(CGSize)newSize
{
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = self.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
