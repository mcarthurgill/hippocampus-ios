//
//  SHBucketsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHBucketsViewController.h"

@interface SHBucketsViewController ()

@end

@implementation SHBucketsViewController

@synthesize tableView;
@synthesize buckets;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.buckets = [[NSMutableArray alloc] init];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(64.0f, 0, 0, 0)];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[LXObjectManager defaultManager] refreshObjectTypes:@"buckets" withAboveUpdatedAt:nil
                                                 success:^(id responseObject){
                                                     self.buckets = [[NSMutableArray alloc] initWithArray:responseObject];
                                                     [self.tableView reloadData];
                                                 }
                                                 failure:^(NSError* error){
                                                 }
     ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark table view delegate and data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.buckets count];
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"bucketCell"];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[[self.buckets objectAtIndex:indexPath.row] firstName]];
    
    return cell;
}


@end
