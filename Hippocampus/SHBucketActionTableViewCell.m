//
//  SHBucketActionTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHBucketActionTableViewCell.h"

@implementation SHBucketActionTableViewCell

@synthesize localKey;
@synthesize delegate;
@synthesize action;

@synthesize label;
@synthesize imageView;

- (void)awakeFromNib
{
    [self.label setFont:[UIFont titleFontWithSize:14.0f]];
    [self.label setTextColor:[UIColor SHBlue]];
    
    [self.imageView setTintColor:[UIColor SHBlue]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}




# pragma mark helpers

- (NSMutableDictionary*) bucket
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}





# pragma mark configure

- (void) configureWithLocalKey:(NSString*)lk delegate:(id)d action:(NSString*)a
{
    [self setLocalKey:lk];
    [self setDelegate:d];
    [self setAction:a];
    
    if ([self.action isEqualToString:@"rename"]) {
        [self.label setText:@"Rename Bucket"];
        [self.imageView setImage:[UIImage imageNamed:@"action_icon_flag.png"]];
    } else if ([self.action isEqualToString:@"delete"]) {
        [self.label setText:[NSString stringWithFormat:@"Delete \"%@\"", [[self bucket] firstName]]];
        [self.imageView setImage:[UIImage imageNamed:@"action_icon_trash.png"]];
    }
}

@end
