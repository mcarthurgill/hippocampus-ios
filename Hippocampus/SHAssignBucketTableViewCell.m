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
}



# pragma mark selection/highlights

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self selectCell:selected];
}



# pragma mark configure

- (void) configureWithBucketLocalKey:(NSString*)key
{
    [self setLocalKey:key];
    
    [self.title setText:[[self bucket] firstName]];
    [self.preview setText:[[self bucket] cachedItemMessage]];
}

- (void) selectCell:(BOOL)selected
{
    if (selected) {
        [self.checkImage setImage:[UIImage imageNamed:@"filled_check.png"]];
    } else {
        [self.checkImage setImage:[UIImage imageNamed:@"empty_check.png"]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"assignBucketsCellSelected" object:nil userInfo:nil];
}



# pragma mark helpers

- (NSMutableDictionary*) bucket
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}

@end
