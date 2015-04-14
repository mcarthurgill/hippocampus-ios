//
//  HCBucketDetailsViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/18/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCBucketDetailsViewController.h"
#import "HCDetailsPhotoTableViewCell.h"
#import "HCChangeBucketTypeViewController.h"
#import "HCCollaborateViewController.h"

@interface HCBucketDetailsViewController ()

@end

@implementation HCBucketDetailsViewController

@synthesize bucket; 
@synthesize tableView;
@synthesize sections;
@synthesize actionCells;
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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self getBucketInfo];
}

- (void) setup
{
    [self.navigationItem setTitle:[self.bucket firstName]];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveInfo)];
    
    [self setUnsavedChanges:NO andSavingChanges:NO];
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
    self.actionCells = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"bucketName"];
    [self.sections addObject:@"collaborate"];
    [self.sections addObject:@"bucketType"];
    
    //figure out action cells here
    if ([self.bucket belongsToCurrentUser]) {
        [self.actionCells addObject:@"deleteBucket"];
        [self.actionCells addObject:@"changeBucketType"];
    }
    
    //add actions section if there are action cells
    if ([self.actionCells count] > 0) {
        [self.sections addObject:@"actions"];
    }
    
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"collaborate"]) {
        return [self.bucket hasCollaborators] ? [[self.bucket bucketUserPairs] count] + 1 : 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketType"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return [self.actionCells count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return ([self.bucket mediaURLs].count%2 == 0) ? [self.bucket mediaURLs].count/2 : [self.bucket mediaURLs].count/2 + 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketName"]) {
        return [self bucketNameCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborate"]) {
        return [self collaborateCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketType"]) {
        return [self bucketTypeCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if ([[self.actionCells objectAtIndex:indexPath.row] isEqualToString:@"deleteBucket"]) {
            return [self deleteBucketCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
        } else if ([[self.actionCells objectAtIndex:indexPath.row] isEqualToString:@"changeBucketType"]) {
            return [self changeBucketTypeCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
        }
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

- (UITableViewCell*) collaborateCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"collaborateCell" forIndexPath:indexPath];
    UILabel* collaborateLabel = (UILabel*)[cell.contentView viewWithTag:1];
    if ([self.bucket hasCollaborators] && indexPath.row != [[self.bucket bucketUserPairs] count]) {
        [collaborateLabel setText:[[[self.bucket bucketUserPairs] objectAtIndex:indexPath.row] objectForKey:@"name"]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    } else if ([self.bucket hasCollaborators]) {
        [collaborateLabel setText:@"+ Add Collaborators"];
        [collaborateLabel boldSubstring:collaborateLabel.text];
    } else {
        [collaborateLabel setText:@"+ Add Collaborators"];
        [collaborateLabel boldSubstring:collaborateLabel.text];
    }
    return cell;
}

- (UITableViewCell*) bucketTypeCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"bucketTypeCell" forIndexPath:indexPath];
    UILabel* changeTypeLabel = (UILabel*)[cell.contentView viewWithTag:1];
    [changeTypeLabel setText:[self.bucket bucketType]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (UITableViewCell*) changeBucketTypeCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"bucketTypeCell" forIndexPath:indexPath];
    UILabel* changeTypeLabel = (UILabel*)[cell.contentView viewWithTag:1];
    [changeTypeLabel setText:@"Change Thread Type"];
    [changeTypeLabel boldSubstring:changeTypeLabel.text];
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
    
    [cell configureWithMediaUrl:[[self.bucket mediaURLs] objectAtIndex:(indexPath.row)*2] andImageView:leftImage];
    [self finishConfigurationForImageView:leftImage];

    if ((indexPath.row)*2 + 1 < [[self.bucket mediaURLs] count]) {
        [cell configureWithMediaUrl:[[self.bucket mediaURLs] objectAtIndex:(indexPath.row)*2 + 1] andImageView:rightImage];
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborate"]) {
        return 50.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketType"]) {
        return 50.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        return 50.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return 200.0f;
    }

    return 44.0f;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"actions"]) {
        if ([[self.actionCells objectAtIndex:indexPath.row] isEqualToString:@"deleteBucket"]) {
            [self alertForDeletion];
        } else if ([[self.actionCells objectAtIndex:indexPath.row] isEqualToString:@"changeBucketType"]) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
            HCChangeBucketTypeViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"changeBucketTypeViewController"];
            [vc setBucketDict:self.bucket];
            [vc setDelegate:self];
            [self.navigationController presentViewController:vc animated:YES completion:nil];
        }
    } else if (([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborate"]) && ([self.bucket hasCollaborators] ? indexPath.row == [[self.bucket bucketUserPairs] count] : indexPath.row == 0)) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCCollaborateViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"collaborateViewController"];
        [vc setBucket:self.bucket];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketName"]) {
        return @"Thread Name";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"collaborate"]) {
        return @"Collaborators";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketType"]) {
        return @"Thread Type";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
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

- (void) getBucketInfo
{
    if (![self.bucket isAllNotesBucket]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[LXServer shared] getBucketInfoWithPage:0 bucketID:[self.bucket ID] success:^(id responseObject) {
                [self refreshWithResponseObject:responseObject];
            }failure:^(NSError *error) {
                NSLog(@"damn!");
            }];
        });
    }
}

- (void) refreshWithResponseObject:(NSDictionary*)responseObject
{
    [self setBucket:[[responseObject objectForKey:@"bucket"] mutableCopy]];
    [self.tableView reloadData];
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
            mediaUrl = [[self.bucket mediaURLs] objectAtIndex:(indexPath.row)*2];
        } else {
            mediaUrl = [[self.bucket mediaURLs] objectAtIndex:(indexPath.row)*2 + 1];
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
    return [self.bucket mediaURLs] && [[self.bucket mediaURLs] count] > 0;
}

# pragma mark - HCUpdateBucketTypeDelegate

-(void)updateBucketType:(NSMutableDictionary *)updatedBucket
{
    self.bucket = updatedBucket;
    [self saveInfo]; 
}



@end
