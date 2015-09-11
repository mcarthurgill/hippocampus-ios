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
@synthesize label;

- (void)awakeFromNib
{
    [self.label setFont:[UIFont titleFontWithSize:15.0f]];
    [self.label setTextColor:[UIColor SHFontDarkGray]];
    
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
        [self.label setText:[[self item] message]];
    } else {
        [self.label setText:@"Tap here to add text."];
        [self.label setTextColor:[UIColor SHFontLightGray]];
        [self.label setFont:[UIFont titleFontWithSize:13.0f]];
    }
    
    [self setNeedsLayout];
}


@end
