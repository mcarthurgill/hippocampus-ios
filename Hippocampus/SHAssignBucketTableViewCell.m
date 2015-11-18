//
//  SHAssignBucketTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHAssignBucketTableViewCell.h"

@implementation SHAssignBucketTableViewCell

@synthesize localKey;
@synthesize contact;
@synthesize checkImage;
@synthesize title;
@synthesize preview;

- (void)awakeFromNib
{
    [self setupAppearanceSettings];
}

- (void) setupAppearanceSettings
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.title setFont:[UIFont titleFontWithSize:15.0f]];
    [self.title setTextColor:[UIColor SHFontDarkGray]];
    
    [self.preview setFont:[UIFont secondaryFontWithSize:12.0f]];
    [self.preview setTextColor:[UIColor lightGrayColor]];
    
    [self.checkImage.layer setCornerRadius:12.5f];
    [self.checkImage setClipsToBounds:YES];
}



# pragma mark selection/highlights

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self selectCell:selected];
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [self selectCell:YES];
    } else if (![self isSelected]) {
        [self selectCell:NO];
    }
}


# pragma mark configure

- (void) configureWithBucketLocalKey:(NSString*)key
{
    [self setLocalKey:key];
    [self setContact:nil];
    
    [self.title setText:[NSString stringWithFormat:@"%@%@", [[self bucket] firstName], ([[[self bucket] itemsCount] integerValue] > 0 ? [NSString stringWithFormat:@" (%i)", [[[self bucket] itemsCount] intValue]] : @"")]];
    [self.preview setText:([[self bucket] ID] ? [[self bucket] cachedItemMessage] : @"New Bucket")];
    
    [self setNeedsLayout];
}

- (void) configureWithContact:(NSMutableDictionary*)cntct
{
    [self setContact:cntct];
    [self setLocalKey:nil];
    
    [self.title setText:[self.contact objectForKey:@"name"]];
    [self.preview setText:@"Create Bucket for Contact"];
    
    [self setNeedsLayout];
}

- (void) selectCell:(BOOL)selected
{
    if ([self contact]) {
        if (selected) {
            [self.checkImage setImage:[UIImage imageNamed:@"filled_check.png"]];
        } else if ([contact objectForKey:@"image"]) {
            [self.checkImage setImage:[contact objectForKey:@"image"]];
        } else {
            [self.checkImage setImage:[UIImage imageNamed:@"avatar.png"]];
        }
    } else {
        if (selected) {
            [self.checkImage setImage:[UIImage imageNamed:@"filled_check.png"]];
        } else {
            [self.checkImage setImage:[UIImage imageNamed:@"empty_check.png"]];
        }
    }
}



# pragma mark helpers

- (NSMutableDictionary*) bucket
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}

@end
