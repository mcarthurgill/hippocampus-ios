//
//  HCExplanationTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCExplanationTableViewCell.h"

@implementation HCExplanationTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) configureWithText:(NSString *)text {
    UILabel* explanation = (UILabel*)[self.contentView viewWithTag:1];
    [explanation setText:text];
}
@end
