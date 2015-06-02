//
//  LXRemindersViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCItemTableViewCell.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define PICTURE_HEIGHT 280
#define PICTURE_MARGIN_TOP 8

@interface LXRemindersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, HCItemCellDelegate>
{
    BOOL requestMade;
    BOOL shouldContinueRequesting;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* allItems;
@property int page;

@end
