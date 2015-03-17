//
//  HCIndicatorTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCIndicatorTableViewCell.h"

@implementation HCIndicatorTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) configureAndBeginAnimation {
    UIActivityIndicatorView* iav = (UIActivityIndicatorView*)[self.contentView viewWithTag:10];
    [iav startAnimating];
}
@end
