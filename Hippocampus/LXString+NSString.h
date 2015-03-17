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

@end
