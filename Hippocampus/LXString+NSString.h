//
//  LXString+NSString.h
//  Hippocampus
//
//  Created by Will Schreiber on 1/21/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LXString)

- (NSString*) truncated:(int)length;

+ (NSString*) randomCongratulations;

- (NSString*) croppedImageURLToScreenWidth;
- (NSString*) croppedImageURLToWidth:(NSInteger)width;

- (NSString*) fileExtension;

- (BOOL) isImageUrl;

- (NSString*) cloudinaryPublicID;

- (CGFloat) heightForTextWithWidth:(CGFloat)width font:(UIFont*)font;

- (NSString*) objectTypeFromLocalKey;

- (NSString*) deviceTimestampFromLocalKey;

- (NSString*) userIDFromLocalKey;

@end
