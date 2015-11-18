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
@synthesize leadingMarginConstraint;

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
        [self.titleLabel setBackgroundColor:[UIColor SHGreen]];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        //[self.secondaryLabel setTextColor:[UIColor whiteColor]];
    } else {
        [self.titleLabel setBackgroundColor:[UIColor whiteColor]];
        [self.titleLabel setTextColor:[UIColor SHFontDarkGray]];
        //[self.secondaryLabel setTextColor:[UIColor SHFontLightGray]];
    }
}

- (void) setupAppearance
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.titleLabel setTextColor:[UIColor SHFontDarkGray]];
    [self.titleLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.titleLabel.layer setCornerRadius:5];
    [self.titleLabel setClipsToBounds:YES];
    [self.titleLabel.layer setBorderColor:[[UIColor SHFontDarkGray] colorWithAlphaComponent:0.2f].CGColor];
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
    
    //[self.titleLabel setText:[NSString stringWithFormat:@"    %@    ", [[self tagObject] tagName]]];
    //[self.secondaryLabel setText:[NSString stringWithFormat:@"%@ Buckets", [[self tagObject] numberBuckets]]];
    
    NSMutableAttributedString* titleString;
    titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@ (%@)  ", [[self tagObject] tagName], [[self tagObject] numberBuckets]]];
    [titleString addAttribute:NSFontAttributeName value:[UIFont secondaryFontWithSize:16.0f] range:NSMakeRange(0,[[self tagObject] tagName].length+2)];
    [titleString addAttribute:NSFontAttributeName value:[UIFont secondaryFontWithSize:14.0f] range:NSMakeRange([[self tagObject] tagName].length+2,[titleString length]-([[self tagObject] tagName].length+2))];
    
    [self.titleLabel setAttributedText:titleString];
}

@end
