//
//  HCNewBucketTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCNewBucketTableViewController.h"
#import "HCNewBucketIITableViewController.h"

@interface HCNewBucketTableViewController ()

@end

@implementation HCNewBucketTableViewController

@synthesize cancelButton;
@synthesize saveButton;
@synthesize bucket;
@synthesize bucketTypes;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setBucketTypes:[HCBucket bucketTypes]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.bucketTypes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectionCell" forIndexPath:indexPath];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setText:[self.bucketTypes objectAtIndex:indexPath.row]];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    HCNewBucketIITableViewController* bc = [storyboard instantiateViewControllerWithIdentifier:@"newBucketIITableViewController"];
    
    if (!self.bucket) {
        bucket = [[HCBucket alloc] create];
    }
    [bucket setBucketType:[self.bucketTypes objectAtIndex:indexPath.row]];
    [bc setBucket:bucket];
    
    [self.navigationController pushViewController:bc animated:YES];
}


# pragma mark actions

- (IBAction)cancelAction:(id)sender
{
    if (self.bucket) {
        [self.bucket destroy];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(id)sender
{
}

@end
