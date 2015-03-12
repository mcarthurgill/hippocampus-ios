//
//  HCRandomItemViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/10/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PICTURE_HEIGHT 280
#define PICTURE_MARGIN_TOP 8

@interface HCRandomItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    BOOL requestMade;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *allItems;
@property (strong, nonatomic) NSMutableDictionary *item;

@end
