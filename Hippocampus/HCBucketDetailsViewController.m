//
//  HCBucketDetailsViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/18/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCBucketDetailsViewController.h"
#import "HCDetailsPhotoTableViewCell.h"

@interface HCBucketDetailsViewController ()

@end

@implementation HCBucketDetailsViewController

@synthesize bucket; 
@synthesize tableView;
@synthesize sections;
@synthesize updatedBucketName;
@synthesize delegate;
@synthesize typeOptions;
@synthesize mediaUrls;


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setup
{
    [self.navigationItem setTitle:[self.bucket firstName]];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveInfo)];
    
    [self setUnsavedChanges:NO andSavingChanges:NO];
    
    self.typeOptions = @[@"Other", @"Person", @"Event", @"Place"];
    self.mediaUrls = [[NSMutableArray alloc] init];
    [self getMediaUrls];
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
    if ([self bucketHasMediaUrls]) {
        [self.sections addObject:@"media"];
    }
    
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return (self.mediaUrls.count%2 == 0) ? self.mediaUrls.count/2 : self.mediaUrls.count/2 + 1;
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return [self mediaCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
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

- (UITableViewCell*) mediaCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    HCDetailsPhotoTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];

    UIImageView *leftImage = (UIImageView*)[cell.contentView viewWithTag:1];
    UIImageView *rightImage = (UIImageView*)[cell.contentView viewWithTag:2];
    
    [cell configureWithMediaUrl:[self.mediaUrls objectAtIndex:(indexPath.row)*2] andImageView:leftImage];
    [self finishConfigurationForImageView:leftImage];

    if ((indexPath.row)*2 + 1 < self.mediaUrls.count) {
        [cell configureWithMediaUrl:[self.mediaUrls objectAtIndex:(indexPath.row)*2 + 1] andImageView:rightImage];
        [self finishConfigurationForImageView:rightImage];
    } else {
        [rightImage setImage:nil];
    }
    
    return cell;
}


- (void) finishConfigurationForImageView:(UIImageView*)imageView
{
    [self addTapGestureToImageView:imageView];
    [self setConstraintsForImageView:imageView];
}


- (void) addTapGestureToImageView:(UIImageView *)imageView {
    
    UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    tapped.delegate = self;
    tapped.numberOfTapsRequired = 1;
    [imageView addGestureRecognizer:tapped];
}


- (void) setConstraintsForImageView:(UIImageView *)imageView
{
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *imageViewDict = @{@"imageView":imageView};

    float width = imageView.image.size.width;
    width = self.view.frame.size.width*0.5;
    
    NSArray *constraint_H = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[imageView(%f)]", width - 10.0]options:0 metrics:nil views:imageViewDict];
    
    [imageView addConstraints:constraint_H];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketName"]) {
        return 75.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketType"]) {
        return 150.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"deleteBucket"]) {
        return 50.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return 200.0f;
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return @"Media";
    }
    return nil;
}



# pragma mark - Actions

- (void) saveInfo
{
    [self setUnsavedChanges:YES andSavingChanges:YES];
    
    [[LXServer shared] savebucketWithBucketID:[self.bucket ID] andBucket:self.bucket success:^(id responseObject) {
        [self setUnsavedChanges:NO andSavingChanges:NO];
        [self reloadScreen];
        [self.delegate updateBucket:self.bucket];
    } failure:^(NSError *error) {
        [self setUnsavedChanges:YES andSavingChanges:NO];
        [self reloadScreen];
    }];
}

- (void) deleteBucket
{
    [self showHUDWithMessage:@"Deleting Thread..."];
    [[LXServer shared] deleteBucketWithBucketID:[self.bucket ID] success:^(id responseObject) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self hideHUD];
    }failure:^(NSError *error){
        [self hideHUD];
    }];
}

- (void) updateBucketName
{
    [self.bucket setObject:self.updatedBucketName forKey:@"first_name"];
    [self saveInfo];
}

- (void)setUnsavedChanges:(BOOL)updatedUnsavedChanges andSavingChanges:(BOOL)updatedSavingChanges
{
    unsavedChanges = updatedUnsavedChanges;
    savingChanges = updatedSavingChanges;
    [self updateButtonStatus];
}

- (void) getMediaUrls
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[LXServer shared] getMediaUrlsForBucketID:[self.bucket ID] success:^(id responseObject) {
            [self.mediaUrls addObjectsFromArray:[responseObject objectForKey:@"media_urls"]];
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"error!");
        }];
    });
}


- (void)imageTapped:(UIGestureRecognizer *)gestureRecognizer
{
    UIView *parentCell = gestureRecognizer.view.superview;
    
    while (![parentCell isKindOfClass:[UITableViewCell class]]) {
        parentCell = parentCell.superview;
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)parentCell];
    NSString *mediaUrl;
    UIImageView *imageView = (UIImageView*)[[[self.tableView cellForRowAtIndexPath:indexPath] contentView] viewWithTag:gestureRecognizer.view.tag];
    
    if (imageView.image) {
        if (gestureRecognizer.view.tag == 1) {
            mediaUrl = [self.mediaUrls objectAtIndex:(indexPath.row)*2];
        } else {
            mediaUrl = [self.mediaUrls objectAtIndex:(indexPath.row)*2 + 1];
        }
        [self openImageWithUrl:mediaUrl];
    }
}

-(void)openImageWithUrl:(NSString *)mediaUrl
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mediaUrl]];
}


# pragma mark TextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.updatedBucketName = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [self.navigationItem setTitle:self.updatedBucketName];
    
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(updateBucketName) withObject:nil afterDelay:2.0];
    
    [self setUnsavedChanges:YES andSavingChanges:NO];
    
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    [self setUnsavedChanges:YES andSavingChanges:NO];
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
    [self setUnsavedChanges:YES andSavingChanges:NO];
    [self.bucket setObject:[self.typeOptions objectAtIndex:row] forKey:@"bucket_type"];
    [self saveInfo]; 
}


# pragma  mark - AlertView Delegate

- (void) alertForDeletion
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Delete this thread?"
                                                     message:@"This will also delete all notes that only belong to this thread."
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Delete Thread"];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self deleteBucket];
    }
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


# pragma mark - Helpers

- (BOOL) bucketHasMediaUrls
{
    return self.mediaUrls && self.mediaUrls.count > 0;
}


@end
