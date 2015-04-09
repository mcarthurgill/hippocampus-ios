//
//  HCCollaborateTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCCollaborateTableViewCell.h"

@implementation HCCollaborateTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void) configureWithContact:(NSDictionary*)contact andSelectedContacts:(NSMutableArray *)selectedContacts
{
    UILabel *contactName = (UILabel*)[self.contentView viewWithTag:1];
    [contactName setText:[contact objectForKey:@"name"]];
    
    if ([[LXAddressBook thisBook] sortedByFirstName]) {
        [contactName boldSubstring:[contact objectForKey:@"first_name"]];
    } else {
        [contactName boldSubstring:[contact objectForKey:@"last_name"]];
    }
    
    UILabel *phoneNumberLabel = (UILabel*)[self.contentView viewWithTag:2];
    if ([contact objectForKey:@"phones"] && [[contact objectForKey:@"phones"] count] > 0) {
        [phoneNumberLabel setText:[[contact objectForKey:@"phones"] objectAtIndex:0]];
    } else {
        [phoneNumberLabel setText:@"Invite to collaborate"];
    }
    
    if ([selectedContacts containsObject:contact]) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
