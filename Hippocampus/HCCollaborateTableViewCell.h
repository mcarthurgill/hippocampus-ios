//
//  HCCollaborateTableViewCell.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCCollaborateTableViewCell : UITableViewCell

- (void) configureWithContact:(NSDictionary*)contact andSelectedContacts:(NSMutableArray*)selectedContacts;

@end
