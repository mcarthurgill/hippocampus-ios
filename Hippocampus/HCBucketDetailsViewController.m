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
@synthesize typeOptions;

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
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    self.navigationItem.rightBarButtonItem =
                                    [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(saveInfo)];
    unsavedChanges = NO;
    savingChanges = NO;
    self.typeOptions = @[@"Other", @"Person", @"Event", @"Place"];
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
    [self.sections addObject:@"bucketType"];
    [self.sections addObject:@"deleteBucket"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketName"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketType"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"deleteBucket"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketName"]) {
        return [self bucketNameCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketType"]) {
        return [self bucketTypeCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"deleteBucket"]) {
        return [self deleteBucketCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
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

- (UITableViewCell*) bucketTypeCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"bucketTypeCell" forIndexPath:indexPath];
    UIPickerView* picker = (UIPickerView*)[cell.contentView viewWithTag:1];
    [picker selectRow:[self.typeOptions indexOfObject:[self.bucket bucketType]] inComponent:0 animated:NO];
    return cell;
}

- (UITableViewCell*) deleteBucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"deleteBucketCell" forIndexPath:indexPath];
    UILabel* deleteLabel = (UILabel*)[cell.contentView viewWithTag:1];
    [deleteLabel setText:@"Delete Thread"];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketName"]) {
        return 75.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketType"]) {
        return 150.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"deleteBucket"]) {
        return 50.0f;
    }

    return 44.0f;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"deleteBucket"]) {
        [self alertForDeletion];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketName"]) {
        return @"Thread Name";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketType"]) {
        return @"Thread Type";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"deleteBucket"]) {
        return @"Actions";
    }
    return nil;
}



# pragma mark - Actions

- (void) saveInfo {
    unsavedChanges = YES;
    savingChanges = YES;
    
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
    [self saveInfo];
}

# pragma mark TextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.updatedBucketName = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [self.navigationItem setTitle:self.updatedBucketName];
    
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(updateBucketName) withObject:nil afterDelay:2.0];
    
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



# pragma mark picker view delegate data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.typeOptions count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.typeOptions objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    unsavedChanges = YES;
    savingChanges = NO;
    [self updateButtonStatus];
    [self.bucket setObject:[self.typeOptions objectAtIndex:row] forKey:@"bucket_type"];
    [self saveInfo]; 
}


# pragma  mark - AlertView Delegate

- (void) alertForDeletion {
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Delete this thread?"
                                                     message:@"This will also delete all notes that only belong to this thread."
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Delete Thread"];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self deleteBucket];
    }
}


- (void) deleteBucket {
    [self showHUDWithMessage:@"Deleting Thread..."];
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", [self.bucket ID]] withMethod:@"DELETE" withParamaters:nil
                           success:^(id responseObject){
                               [self.navigationController popToRootViewControllerAnimated:YES];
                               [self hideHUD];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error! %@", [error localizedDescription]);
                               [self hideHUD];
                           }
     ];
}



# pragma mark hud delegate

- (void) showHUDWithMessage:(NSString*) message
{
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = message;
}

- (void) hideHUD
{
    [hud hide:YES];
}



@end
