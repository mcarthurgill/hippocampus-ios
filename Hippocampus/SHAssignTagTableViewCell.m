//
//  SHAssignTagTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHAssignTagTableViewCell.h"

@implementation SHAssignTagTableViewCell

@synthesize localKey;
@synthesize titleLabel;

- (void)awakeFromNib
{
    [self setupAppearance];
}

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

- (void) selectCell:(BOOL)selected
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    if (selected) {
        [self.titleLabel setBackgroundColor:[UIColor SHGreen]];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
    } else {
        [self.titleLabel setBackgroundColor:[UIColor whiteColor]];
        [self.titleLabel setTextColor:[UIColor SHFontDarkGray]];
    }
}

- (void) setupAppearance
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.titleLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.titleLabel setFont:[UIFont secondaryFontWithSize:18.0f]];
    [self.titleLabel setTextColor:[UIColor SHFontDarkGray]];
    [self.titleLabel.layer setCornerRadius:5];
    [self.titleLabel setClipsToBounds:YES];
    [self.titleLabel.layer setBorderColor:[[UIColor SHGreen] colorWithAlphaComponent:0.2f].CGColor];
    [self.titleLabel.layer setBorderWidth:0.8f];
}


# pragma mark helpers

- (NSMutableDictionary*) tagObject
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}


- (void) configureWithTagLocalKey:(NSString*)lk
{
    [self setLocalKey:lk];
    
    [self.titleLabel setText:[NSString stringWithFormat:@"   %@", [[self tagObject] tagName]]];
}

@end
