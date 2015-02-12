//
//  LXRemindersViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface LXRemindersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    BOOL requestMade;
    BOOL shouldContinueRequesting;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* allItems;
@property int page;

@end
