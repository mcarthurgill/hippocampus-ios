//
//  HCContactTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCContactTableViewCell.h"

@implementation HCContactTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void) configureWithContact:(NSDictionary*)contact
{
    UILabel *contactName = (UILabel*)[self.contentView viewWithTag:1];
    [contactName setText:[contact objectForKey:@"name"]];

    if ([[LXAddressBook thisBook] sortedByFirstName]) {
        [contactName boldSubstring:[contact objectForKey:@"first_name"]];
    } else {
        [contactName boldSubstring:[contact objectForKey:@"last_name"]];
    }
    
    UILabel *bottomLabel = (UILabel*)[self.contentView viewWithTag:2];
    [bottomLabel setText:[NSString stringWithFormat:@"Tap to create thread for %@", [contact objectForKey:@"name"]]];
}
@end
