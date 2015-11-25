//
//  LXMediumObject.m
//  Hippocampus
//
//  Created by Will Schreiber on 11/25/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "LXMediumObject.h"

@implementation LXMediumObject

@synthesize mutableDictionary;

- (id) initWithMutableDictionary:(NSMutableDictionary*)md
{
    if (!self) {
        self = [super init];
    }
    [self setMutableDictionary:md];
    return self;
}

- (UIImage*) image
{
    if ([SGImageCache haveImageForURL:[self.mutableDictionary mediaURL]]) {
        return [SGImageCache imageForURL:[self.mutableDictionary mediaURL]];
    } else if ([SGImageCache haveImageForURL:[self.mutableDictionary mediaThumbnailURLWithScreenWidth]]) {
        return [SGImageCache imageForURL:[self.mutableDictionary mediaThumbnailURLWithScreenWidth]];
    }
    return nil;
}

- (UIImage*) placeholderImage
{
    return nil;
}

/**
 *  An attributed string for display as the title of the caption.
 */
- (NSAttributedString*) attributedCaptionTitle
{
    return nil;
}

/**
 *  An attributed string for display as the summary of the caption.
 */
- (NSAttributedString*) attributedCaptionSummary
{
    return nil;
}

/**
 *  An attributed string for display as the credit of the caption.
 */
- (NSAttributedString*) attributedCaptionCredit
{
    return nil;
}

@end
