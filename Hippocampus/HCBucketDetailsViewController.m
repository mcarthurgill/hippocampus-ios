//
//  HCBucketDetailsViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/18/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCBucketDetailsViewController.h"

@interface HCBucketDetailsViewController ()

@end

@implementation HCBucketDetailsViewController

@synthesize bucket; 
@synthesize tableView;
@synthesize sections;
@synthesize updatedBucketName;
@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setup {
    [self.navigationItem setTitle:[self.bucket firstName]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.navigationItem.rightBarButtonItem =
                                    [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(saveInfo)];
    unsavedChanges = NO;
    savingChanges = NO;
    [self updateButtonStatus]; 
}

- (void) reloadScreen
{
    [self.tableView reloadData];
    [self updateButtonStatus];
}

#pragma mark - UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"bucketName"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketName"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketName"]) {
        return [self bucketNameCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) bucketNameCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"bucketNameCell" forIndexPath:indexPath];
    UITextField* bucketName = (UITextField*)[cell.contentView viewWithTag:1];
    [bucketName setText:[self.bucket firstName]];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketName"]) {
        return 50.0f;
    }
    
    return 44.0f;
}

# pragma mark - Actions

- (void) saveInfo {
    unsavedChanges = YES;
    savingChanges = YES;
    [self updateBucketName];
    
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", [self.bucket ID]] withMethod:@"PUT" withParamaters:@{@"bucket":self.bucket}
                           success:^(id responseObject) {
                               unsavedChanges = NO;
                               savingChanges = NO;
                               [self reloadScreen];
                               [self.delegate updateBucket:self.bucket]; 
                           }
                           failure:^(NSError *error) {
                               unsavedChanges = YES;
                               savingChanges = NO;
                               [self reloadScreen];
                           }
     ];
}

- (void) updateBucketName {
    [self.bucket setObject:self.updatedBucketName forKey:@"first_name"];
}

# pragma mark TextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.updatedBucketName = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [self.navigationItem setTitle:self.updatedBucketName];
    
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(saveInfo) withObject:nil afterDelay:2.0];
    
    unsavedChanges = YES;
    savingChanges = NO;
    [self updateButtonStatus];
    
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    unsavedChanges = YES;
    savingChanges = NO;
    [self updateButtonStatus];
}

- (void) updateButtonStatus
{
    if (!unsavedChanges) {
        [self.navigationItem.rightBarButtonItem  setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTitle:@"Saved"];
    } else if (savingChanges) {
        [self.navigationItem.rightBarButtonItem  setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTitle:@"Saving..."];
    } else {
        [self.navigationItem.rightBarButtonItem  setEnabled:YES];
        [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
    }
}
@end
