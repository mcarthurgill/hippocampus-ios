//
//  SHThoughtsViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextViewController.h"

@interface SHThoughtsViewController : SLKTextViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end