//
//  SHLinkMetadataTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 11/4/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHLinkMetadataTableViewCell.h"

@implementation SHLinkMetadataTableViewCell

@synthesize leftImageView;
@synthesize topLabel;
@synthesize middleLabel;
@synthesize bottomLabel;

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
