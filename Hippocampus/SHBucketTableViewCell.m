//
//  SHBucketTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHBucketTableViewCell.h"
@import QuartzCore;

@implementation SHBucketTableViewCell

@synthesize bucketLocalKey;
@synthesize card;
@synthesize bucketName;
@synthesize bucketItemMessage;

- (void)awakeFromNib
{
    // Initialization code
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [card.layer setCornerRadius:4.0f];
    [card setClipsToBounds:YES];
    [card.layer setBorderColor:[UIColor SHLightGray].CGColor];
    [card.layer setBorderWidth:1.0f];
    
    [bucketName setFont:[UIFont titleFontWithSize:16.0f]];
    
    [bucketItemMessage setFont:[UIFont titleFontWithSize:14.0f]];
    [bucketItemMessage setTextColor:[UIColor SHFontLightGray]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) configureWithBucketLocalKey:(NSString*)key
{
    [self setBucketLocalKey:key];
    
    NSMutableDictionary* bucket = [LXObjectManager objectWithLocalKey:self.bucketLocalKey];
    
    NSMutableAttributedString* titleString;
    if ([bucket itemsCount]) {
        titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)", [bucket firstName], [bucket itemsCount]]];
        [titleString addAttribute:NSForegroundColorAttributeName value:[UIColor SHFontPurple] range:NSMakeRange(0,[bucket firstName].length)];
        [titleString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange([bucket firstName].length,[titleString length]-[bucket firstName].length)];
    } else {
        titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [bucket firstName]]];
        [titleString addAttribute:NSForegroundColorAttributeName value:[UIColor SHFontPurple] range:NSMakeRange(0,[bucket firstName].length)];
    }
    [bucketName setAttributedText:titleString];
    
    [bucketItemMessage setText:[bucket cachedItemMessage]];
    
    //NSLog(@"cellheight: %f, label heights: %f %f", self.frame.size.height, bucketName.frame.size.height, bucketItemMessage.frame.size.height);
    
}

@end
