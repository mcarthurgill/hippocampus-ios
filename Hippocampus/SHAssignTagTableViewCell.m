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
@synthesize card;
@synthesize titleLabel;
@synthesize secondaryLabel;

- (void)awakeFromNib
{
    [self setupAppearance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
}

- (void) refreshedObject:(NSNotification*)notification
{
    if (NULL_TO_NIL([[notification userInfo] objectForKey:@"local_key"])) {
        if ([[notification userInfo] objectForKey:@"local_key"] && self.localKey && [[[notification userInfo] objectForKey:@"local_key"] isEqualToString:self.localKey]) {
            //this is a hit, a currently displaying talbeivewcell. reload it.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshTagsViewController" object:nil userInfo:@{@"local_key":self.localKey}];
        }
    }
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
        [self.card setBackgroundColor:[UIColor SHGreen]];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [self.secondaryLabel setTextColor:[UIColor whiteColor]];
    } else {
        [self.card setBackgroundColor:[UIColor whiteColor]];
        [self.titleLabel setTextColor:[UIColor SHFontDarkGray]];
        [self.secondaryLabel setTextColor:[UIColor SHFontLightGray]];
    }
}

- (void) setupAppearance
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.card.layer setCornerRadius:5];
    [self.card setClipsToBounds:YES];
    [self.card.layer setBorderColor:[[UIColor SHGreen] colorWithAlphaComponent:0.2f].CGColor];
    [self.card.layer setBorderWidth:0.8f];
    [self.card setBackgroundColor:[UIColor whiteColor]];
    
    [self.titleLabel setFont:[UIFont titleFontWithSize:16.0f]];
    [self.titleLabel setTextColor:[UIColor SHFontDarkGray]];
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    
    [self.secondaryLabel setFont:[UIFont secondaryFontWithSize:13.0f]];
    [self.secondaryLabel setTextColor:[UIColor SHFontLightGray]];
    [self.secondaryLabel setBackgroundColor:[UIColor clearColor]];
}


# pragma mark helpers

- (NSMutableDictionary*) tagObject
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}


- (void) configureWithTagLocalKey:(NSString*)lk
{
    [self setLocalKey:lk];
    
    [self.titleLabel setText:[NSString stringWithFormat:@"%@", [[self tagObject] tagName]]];
    [self.secondaryLabel setText:[NSString stringWithFormat:@"%@ Buckets", [[self tagObject] numberBuckets]]];
}

@end
