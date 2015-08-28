//
//  SHLoadingTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHLoadingTableViewCell.h"

@implementation SHLoadingTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    inverted = NO;
    
    if (!inverted) {
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        inverted = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) configure
{
    NSLog(@"height: %f", self.frame.size.height);
}

@end
