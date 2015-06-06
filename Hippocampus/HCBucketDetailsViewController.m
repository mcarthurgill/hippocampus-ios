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
#import "LXAppDelegate.h"

@interface HCBucketDetailsViewController ()

@end

@implementation HCBucketDetailsViewController

@synthesize bucket; 
@synthesize tableView;
@synthesize sections;
@synthesize actionCells;
@synthesize updatedBucketName;
@synthesize delegate;
@synthesize bucketUserPairForDeletion;
@synthesize moviePlayerController;
@synthesize mediaView;
@synthesize player;
@synthesize playerLayer;
@synthesize asset;
@synthesize playerItem;


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
    
    [self setLongPressGestureToRemoveCollaborator];
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
        //[self.actionCells addObject:@"changeBucketType"];
    }
    
    if ([self.bucket hasCollaborators]) {
        [self.actionCells addObject:@"leaveThread"];
    }
    
    //add actions section if there are action cells
    if ([self.actionCells count] > 0) {
        [self.sections addObject:@"actions"];
    }
    
    if ([[self.bucket bucketType] isEqualToString:@"Person"]) {
        [self.sections addObject:@"contactCard"];
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"contactCard"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return ([self.bucket croppedMediaURLs].count%2 == 0) ? [self.bucket croppedMediaURLs].count/2 : [self.bucket croppedMediaURLs].count/2 + 1;
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
        } else if ([[self.actionCells objectAtIndex:indexPath.row] isEqualToString:@"leaveThread"]) {
            return [self leaveThreadTypeCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contactCard"]) {
        return [self contactCardCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
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
    UITableViewCell *cell;
    if ([self.bucket hasCollaborators] && indexPath.row != [[self.bucket bucketUserPairs] count]) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"collaborateCell" forIndexPath:indexPath];

        UILabel* collaborateLabel = (UILabel*)[cell.contentView viewWithTag:1];
        [collaborateLabel setText:[[[self.bucket bucketUserPairs] objectAtIndex:indexPath.row] name]];
        //UILabel* phoneLabel = (UILabel*)[cell.contentView viewWithTag:2];
        //[phoneLabel setText:[[[self.bucket bucketUserPairs] objectAtIndex:indexPath.row] phoneNumber]];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    } else if ([self.bucket hasCollaborators]) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"collaborateCell" forIndexPath:indexPath];
        
        UILabel* collaborateLabel = (UILabel*)[cell.contentView viewWithTag:1];
        [collaborateLabel setText:@"+ Add Collaborators"];
        [collaborateLabel boldSubstring:collaborateLabel.text];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"collaborateCell" forIndexPath:indexPath];
        
        UILabel* collaborateLabel = (UILabel*)[cell.contentView viewWithTag:1];
        [collaborateLabel setText:@"+ Add Collaborators"];
        [collaborateLabel boldSubstring:collaborateLabel.text];
    }
    return cell;
}

- (UITableViewCell*) bucketTypeCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"bucketTypeCell" forIndexPath:indexPath];
    UILabel* changeTypeLabel = (UILabel*)[cell.contentView viewWithTag:1];
    [changeTypeLabel setText:[self.bucket getGroupName]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    return cell;
}

- (UITableViewCell*) changeBucketTypeCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"bucketTypeCell" forIndexPath:indexPath];
    UILabel* changeTypeLabel = (UILabel*)[cell.contentView viewWithTag:1];
    [changeTypeLabel setText:@"Change Collection Type"];
    [changeTypeLabel boldSubstring:changeTypeLabel.text];
    return cell;
}

- (UITableViewCell*) leaveThreadTypeCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"leaveThreadCell" forIndexPath:indexPath];
    UILabel* changeTypeLabel = (UILabel*)[cell.contentView viewWithTag:1];
    [changeTypeLabel setText:@"Leave Collection"];
    return cell;
}

- (UITableViewCell*) deleteBucketCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"deleteBucketCell" forIndexPath:indexPath];
    UILabel* deleteLabel = (UILabel*)[cell.contentView viewWithTag:1];
    [deleteLabel setText:@"Delete Collection"];
    return cell;
}

- (UITableViewCell*) contactCardCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"contactCardCell" forIndexPath:indexPath];
    UILabel* contactLabel = (UILabel*)[cell.contentView viewWithTag:1];
    UILabel* phoneLabel = (UILabel*)[cell.contentView viewWithTag:2];
    
    if ([self.bucket hasContacts]) {
        [contactLabel setText:[[self.bucket contactCard] name]];
        [phoneLabel setText:[[self.bucket contactCard] firstPhone]];
        [phoneLabel setHidden:NO];
    } else {
        [phoneLabel setHidden:YES];
        [contactLabel setText:@"Add Contact"];
        [contactLabel boldSubstring:contactLabel.text];
    }
    return cell;
}


- (UITableViewCell*) mediaCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    HCDetailsPhotoTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];

    UIImageView *leftImage = (UIImageView*)[cell.contentView viewWithTag:1];
    UIImageView *rightImage = (UIImageView*)[cell.contentView viewWithTag:2];
    
    [cell configureWithMediaUrl:[self mediaUrlAtIndexPath:indexPath withTag:leftImage.tag] andImageView:leftImage];
    [self finishConfigurationForImageView:leftImage];

    if ((indexPath.row)*2 + 1 < [[self.bucket croppedMediaURLs] count]) {
        [cell configureWithMediaUrl:[self mediaUrlAtIndexPath:indexPath withTag:rightImage.tag] andImageView:rightImage];
        [self finishConfigurationForImageView:rightImage];
    } else {
        [rightImage setImage:nil];
    }
    
    for (UIGestureRecognizer *recognizer in leftImage.gestureRecognizers) {
        [leftImage removeGestureRecognizer:recognizer];
    }
    for (UIGestureRecognizer *recognizer in rightImage.gestureRecognizers) {
        [rightImage removeGestureRecognizer:recognizer];
    }
    
    UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressMedia:)];
    [longPress setMinimumPressDuration:0.15f];
    [leftImage addGestureRecognizer:longPress];
    [leftImage setUserInteractionEnabled:YES];
    [leftImage setExclusiveTouch:YES];
    [self addTapGestureToImageView:leftImage];
    
    UILongPressGestureRecognizer* longPressRight = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressMedia:)];
    [longPressRight setMinimumPressDuration:0.15f];
    [rightImage addGestureRecognizer:longPressRight];
    [rightImage setUserInteractionEnabled:YES];
    [rightImage setExclusiveTouch:YES];
    [self addTapGestureToImageView:rightImage];
    
    return cell;
}

- (NSString*) mediaUrlAtIndexPath:(NSIndexPath*)indexPath withTag:(NSInteger)tag
{
    return [[self.bucket croppedMediaURLs] objectAtIndex:(indexPath.row)*2 + tag-1];
}


- (void) finishConfigurationForImageView:(UIImageView*)imageView
{
    [self setConstraintsForImageView:imageView];
}


- (void) addTapGestureToImageView:(UIImageView *)imageView
{
    
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contactCard"]) {
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
        } else if ([[self.actionCells objectAtIndex:indexPath.row] isEqualToString:@"leaveThread"]) {
            [self alertForLeavingThread];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"bucketType"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCChangeBucketTypeViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"changeBucketTypeViewController"];
        [vc setBucketDict:self.bucket];
        [vc setDelegate:self];
        [self.navigationController presentViewController:vc animated:YES completion:nil];
    } else if (([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborate"]) && ([self.bucket hasCollaborators] ? indexPath.row == [[self.bucket bucketUserPairs] count] : indexPath.row == 0)) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCCollaborateViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"collaborateViewController"];
        [vc setBucket:self.bucket];
        [vc setIsCollaborating:YES];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contactCard"] && [self.bucket hasContacts]) {
        [self alertForRemovingContact];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contactCard"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCCollaborateViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"collaborateViewController"];
        [vc setBucket:self.bucket];
        [vc setIsCollaborating:NO];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketName"]) {
        return @"Collection Name";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"collaborate"]) {
        return @"Collaborators";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"bucketType"]) {
        return @"Group";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return @"Actions";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"contactCard"]) {
        return @"Contacts";
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
    [self showHUDWithMessage:@"Deleting Collection..."];
    [[LXServer shared] deleteBucketWithBucketID:[self.bucket ID] success:^(id responseObject) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self hideHUD];
    }failure:^(NSError *error){
        [self hideHUD];
    }];
}

- (void) removeContact
{
    [self showHUDWithMessage:@"Removing Contact..."];
    [[LXServer shared] deleteContactCard:[[self.bucket contactCard] mutableCopy] success:^(id responseObject) {
        [self getBucketInfo];
        [self hideHUD];
    }failure:^(NSError *error){
        [self hideHUD];
    }];
}

- (void) leaveThread
{
    [self showHUDWithMessage:@"Leaving Collection..."];
    [[LXServer shared] deleteBucketUserPairWithBucketID:[self.bucket ID] andPhoneNumber:[[HCUser loggedInUser] phone] success:^(id responseObject) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self hideHUD];
    }failure:^(NSError *error){
        [self hideHUD];
    }];
}

- (void) removeCollaborator
{
    [self showHUDWithMessage:@"Removing..."];
    [[LXServer shared] deleteBucketUserPairWithBucketID:[self.bucket ID] andPhoneNumber:[self.bucketUserPairForDeletion objectForKey:@"phone_number"] success:^(id responseObject) {
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
//                NSLog(@"bucketInfo: %@", responseObject);
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
    if ([responseObject objectForKey:@"group"]) {
        [self.bucket setObject:[responseObject objectForKey:@"group"] forKey:@"group"];
    }
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
    
    if (gestureRecognizer.view.tag == 1) {
        mediaUrl = [[self.bucket croppedMediaURLs] objectAtIndex:(indexPath.row)*2];
    } else {
        mediaUrl = [[self.bucket croppedMediaURLs] objectAtIndex:(indexPath.row)*2 + 1];
    }
    
    NSUInteger indexOfVideoUrl = [self.bucket indexOfMatchingVideoUrl:mediaUrl];
    if (indexOfVideoUrl != -1) {
        NSURL *movieURL = [NSURL URLWithString:[[self.bucket mediaURLs] objectAtIndex:indexOfVideoUrl]];
        self.moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
        [self presentMoviePlayerViewControllerAnimated:self.moviePlayerController];
        [self.moviePlayerController.moviePlayer play];
    } else {
        if (imageView.image) {
            if (gestureRecognizer.view.tag == 1) {
                mediaUrl = [[self.bucket croppedMediaURLs] objectAtIndex:(indexPath.row)*2];
            } else {
                mediaUrl = [[self.bucket croppedMediaURLs] objectAtIndex:(indexPath.row)*2 + 1];
            }
            [self openImageWithUrl:mediaUrl];
        }
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
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Delete this collection?"
                                                     message:@"This will also delete all thoughts that only belong to this collection."
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Delete Collection"];
    [alert setTag:1];
    [alert show];
}

- (void) alertForRemovingContact
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Remove?"
                                                     message:[NSString stringWithFormat:@"Are you sure you want to remove the contact card for %@", [[self.bucket contactCard] name]]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Remove"];
    [alert setTag:4];
    [alert show];
}


- (void) alertForLeavingThread
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Leave this collection?"
                                                     message:@"Are you sure you want to leave this collection?"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Leave"];
    [alert setTag:2];
    [alert show];
}

- (void) alertForRemoveCollaborator
{
    NSString *title = @"Remove?";
    NSString *message = [NSString stringWithFormat:@"This will remove %@ from this collection.", [self.bucketUserPairForDeletion name]];
    NSString *cancelButton = @"Cancel";
    NSString *removeButton = @"Remove";
    
    if (self.bucketUserPairForDeletion && [[self.bucketUserPairForDeletion objectForKey:@"phone_number"] isEqualToString:[[self.bucket creator] objectForKey:@"phone"]]) {
        title = @"Sorry";
        message = @"You cannot remove the creator of this collection.";
        cancelButton = nil;
        removeButton = @"Okay";
        [self setBucketUserPairForDeletion:nil];
    }
    
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:cancelButton
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:removeButton];
    [alert setTag:3];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == 1) {
        [self deleteBucket];
    } else if (buttonIndex == 1 && alertView.tag == 2) {
        [self leaveThread];
    } else if (buttonIndex == 1 && alertView.tag == 3) {
        [self removeCollaborator];
    } else if (buttonIndex == 1 && alertView.tag == 4) {
        [self removeContact];
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
    return [self.bucket croppedMediaURLs] && [[self.bucket croppedMediaURLs] count] > 0;
}


# pragma mark - HCUpdateBucketTypeDelegate

-(void)updateBucketGroup:(NSMutableDictionary *)updatedBucket
{
    self.bucket = updatedBucket;
    
    [self setUnsavedChanges:NO andSavingChanges:NO];
    [self reloadScreen];
    [self.delegate updateBucket:self.bucket];
}


# pragma mark - Gesture Recognizers

- (void) setLongPressGestureToRemoveCollaborator
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.4; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborate"] && [[self.bucket bucketUserPairs] objectAtIndex:indexPath.row]) {
            [self setBucketUserPairForDeletion:[[self.bucket bucketUserPairs] objectAtIndex:indexPath.row]];
            [self alertForRemoveCollaborator];
        }
    }
}


# pragma mark long press media

- (void) longPressMedia:(UILongPressGestureRecognizer*)gesture
{
    
    CGPoint p = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed || gesture.state == UIGestureRecognizerStateEnded) {
        if (self.mediaView) {
            [self.mediaView removeFromSuperview];
            [self setMediaView:nil];
        }
        if (self.player) {
            [self.player pause];
            [self setPlayer:nil];
            [self setAsset:nil];
            [self setPlayerItem:nil];
            [self setPlayerLayer:nil];
        }
        [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelNormal];
    }
    
    else if (!self.mediaView) {
        
        id cell = [gesture view];
        while (![cell isKindOfClass:[UITableViewCell class]]) {
            cell = [cell superview];
        }
        
        //int index = (int)[[self.tableView indexPathForCell:cell] row];
        [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelStatusBar+1];
        // Get main window reference
        UIWindow* mainWindow = (((LXAppDelegate *)[UIApplication sharedApplication].delegate).window);
        
        NSString *url = [self mediaUrlAtIndexPath:indexPath withTag:gesture.view.tag];
        NSUInteger indexOfVideoUrl = [self.bucket indexOfMatchingVideoUrl:url];
        
        // Create a full-screen subview
        self.mediaView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height+[[UIApplication sharedApplication] statusBarFrame].size.height)];
        // Set up some properties of the subview
        self.mediaView.backgroundColor = [UIColor blackColor];
        [self.mediaView setContentMode:UIViewContentModeScaleAspectFit];
        
        if (indexOfVideoUrl != -1) {
            //VIDEO
            
            if (!self.player) {
                
                //NSLog(@"mediaURL: %@", [[self.bucket mediaURLs] objectAtIndex:indexOfVideoUrl]);
                self.asset = [AVAsset assetWithURL:[NSURL URLWithString:[[self.bucket mediaURLs] objectAtIndex:indexOfVideoUrl]]];
                if (!self.playerItem) {
                    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
                }
                if (!self.player) {
                    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
                    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
                }
                
                if (!self.playerLayer) {
                    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
                    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
                    [self.playerLayer setFrame:self.mediaView.frame];
                    [self.mediaView.layer addSublayer:self.playerLayer];
                }
                [self.player play];
                
            }
            
        } else {
            
            //IMAGE
            //if ([self.item hasID]) {
                if ([SGImageCache haveImageForURL:url]) {
                    [self.mediaView setImage:[SGImageCache imageForURL:url]];
                } else if (![self.mediaView.image isEqual:[SGImageCache imageForURL:url]]) {
                    self.mediaView.image = nil;
                    [SGImageCache getImageForURL:url].then(^(UIImage* image) {
                        if (image) {
                            self.mediaView.image = image;
                        }
                    });
                }
            //} else {
            //    if ([NSData dataWithContentsOfFile:url] && ![self.mediaView.image isEqual:[UIImage imageWithData:[NSData dataWithContentsOfFile:url]]]) {
            //        self.mediaView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:url]];
            //    }
            //}
            
        }
        
        // Add the subview to the main window
        [mainWindow addSubview:self.mediaView];
    }
}

- (void) playerItemDidReachEnd:(NSNotification*)notification
{
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}




@end
