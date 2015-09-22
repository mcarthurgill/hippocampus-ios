//
//  SHItemMessageTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemMessageTableViewCell.h"

@implementation SHItemMessageTableViewCell

@synthesize localKey;
@synthesize messageView;
@synthesize messageViewHeight;
@synthesize label;

- (void)awakeFromNib
{
    [self.messageView setFont:[UIFont titleFontWithSize:15.0f]];
    [self.messageView setTextColor:[UIColor SHFontDarkGray]];
    [self.messageView setBackgroundColor:[UIColor clearColor]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}



# pragma mark helper

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}




# pragma mark configure

- (void) configureWithLocalKey:(NSString*)key
{
    [self setLocalKey:key];
    
    if ([[self item] hasMessage]) {
        [self.messageView setText:[[self item] message]];
        [self.messageView setTextColor:[UIColor SHFontDarkGray]];
        [self.messageView setFont:[UIFont titleFontWithSize:15.0f]];
        [self.messageView setHidden:NO];
        [self.label setHidden:YES];
    } else {
        [self.messageView setText:@"Tap here to add text."];
        [self.messageView setTextColor:[UIColor SHFontLightGray]];
        [self.messageView setFont:[UIFont titleFontWithSize:13.0f]];
        [self.messageView setHidden:YES];
        [self.label setText:@"Tap here to add text."];
        [self.label setTextColor:[UIColor SHFontLightGray]];
        [self.label setFont:[UIFont titleFontWithSize:13.0f]];
        [self.label setHidden:NO];
    }
    
    self.messageViewHeight.constant = [self.messageView sizeThatFits:CGSizeMake(self.messageView.bounds.size.width, 10000000)].height + 10.0f;
    
    [self setNeedsLayout];
}


@end
