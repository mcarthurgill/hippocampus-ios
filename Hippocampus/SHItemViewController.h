//
//  SHItemViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray* sections;

@end
