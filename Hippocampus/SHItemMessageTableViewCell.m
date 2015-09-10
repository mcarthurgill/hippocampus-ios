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
    
    [self.label setText:[[self item] message]];
    
    [self setNeedsLayout];
}


@end
