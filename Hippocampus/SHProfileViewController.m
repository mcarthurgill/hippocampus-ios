//
//  SHProfileViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/22/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHProfileViewController.h"
#import "SHUserProfileTableViewCell.h"
#import "LXAppDelegate.h"

static NSString *userProfileIdentifier = @"SHUserProfileTableViewCell";

@interface SHProfileViewController ()

@end

@implementation SHProfileViewController

@synthesize sections;
@synthesize sectionRows;

@synthesize tableView;
@synthesize rightBarButton;
@synthesize profileImageViewFromCell;
@synthesize emailLabelFromCell;


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(askedPermission:) name:@"askedPermission" object:nil];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupSettings
{
    [self setTitle:@"Settings"];
    
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
}




# pragma mark table view delegate

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (void) setRows
{
    self.sectionRows = [[NSMutableDictionary alloc] init];
    for (NSString* section in self.sections) {
        if ([section isEqualToString:@"userProfile"]) {
            [self.sectionRows setObject:@[@"profile"] forKey:section];
        } else if ([section isEqualToString:@"info"]) {
            [self.sectionRows setObject:@[@"version", @"author"] forKey:section];
        } else if ([section isEqualToString:@"actions"]) {
            [self.sectionRows setObject:@[@"email",@"logout"] forKey:section];
        }
    }
}

- (NSString*) rowForIndexPath:(NSIndexPath*)indexPath
{
    return [[self.sectionRows objectForKey:[self.sections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"userProfile"];
    [self.sections addObject:@"info"];
    [self.sections addObject:@"actions"];
    
    [self setRows];
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.sectionRows objectForKey:[self.sections objectAtIndex:section]] count];
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self rowForIndexPath:indexPath] isEqualToString:@"profile"]) {
        SHUserProfileTableViewCell* cell = (SHUserProfileTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:userProfileIdentifier];
        [cell configureWithDelegate:self];
        [cell layoutIfNeeded];
        return cell;
    } else if ([[self rowForIndexPath:indexPath] isEqualToString:@"version"]) {
        return [self tableView:tV descriptionCellWithText:[NSString stringWithFormat:@"Version %@ (Seahorse)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
    } else if ([[self rowForIndexPath:indexPath] isEqualToString:@"author"]) {
        return [self tableView:tableView descriptionCellWithText:@"Made in Nashville"];
    } else if ([[self rowForIndexPath:indexPath] isEqualToString:@"email"]) {
        return [self tableView:tableView actionCellWithText:@"Email the Creators"];
    } else if ([[self rowForIndexPath:indexPath] isEqualToString:@"logout"]) {
        return [self tableView:tableView actionCellWithText:@"Logout"];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tableView descriptionCellWithText:(NSString *)text
{
    UITableViewCell* cell = (UITableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"descriptionCell"];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setFont:[UIFont secondaryFontWithSize:16.0f]];
    [label setTextColor:[UIColor SHFontLightGray]];
    
    [label setText:text];
    
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tableView actionCellWithText:(NSString *)text
{
    UITableViewCell* cell = (UITableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"actionCell"];
    
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
    [label setFont:[UIFont secondaryFontWithSize:16.0f]];
    [label setTextColor:[UIColor SHFontLightGray]];
    
    [label setText:text];
    
    [cell layoutIfNeeded];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self rowForIndexPath:indexPath] isEqualToString:@"profile"]) {
        return 140.0f;
    }
    return 50.0f;
}

- (void) tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tV deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([[self rowForIndexPath:indexPath] isEqualToString:@"email"]) {
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = self;
        [mc setSubject:@"Dear Hippo Creators"];
        [mc setToRecipients:@[@"w@lxv.io", @"m@lxv.io"]];
        [self presentViewController:mc animated:YES completion:^(void){}];
    } else if ([[self rowForIndexPath:indexPath] isEqualToString:@"logout"]) {
        [[[LXSession thisSession] user] logout];
        [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Login"];
    }
}





# pragma mark section headers

- (NSString*) tableView:(UITableView *)tV titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"info"]) {
        return @"App Info";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"actions"]) {
        return @"Actions";
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tV heightForHeaderInSection:(NSInteger)section
{
    if ([self tableView:tV titleForHeaderInSection:section])
        return 36.0f;
    return 0;
}

- (UIView*) tableView:(UITableView *)tV viewForHeaderInSection:(NSInteger)section
{
    if (![self tableView:tV titleForHeaderInSection:section])
        return nil;
    
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tV heightForHeaderInSection:section])];
    [header setBackgroundColor:[UIColor SHLighterGray]];
    
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.frame.size.width, header.frame.size.height)];
    [title setText:[[self tableView:tV titleForHeaderInSection:section] uppercaseString]];
    [title setFont:[UIFont titleFontWithSize:12.0f]];
    [title setTextColor:[UIColor lightGrayColor]];
    
    [header addSubview:title];
    
    return header;
}





# pragma mark helper actions

- (void) showProfileImageActionSheet
{
    UIActionSheet* as = [[UIActionSheet alloc] initWithTitle:@"Change Profile Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ? @"Camera" : nil), nil];
    [as setTag:50];
    [as showInView:self.view];
}





# pragma mark actions

- (void) action:(NSString*)action
{
    NSLog(@"ACTION! %@", action);
    if ([action isEqualToString:@"changeImage"]) {
        [self showProfileImageActionSheet];
    } else if ([action isEqualToString:@"changeName"]) {
        [self showAlertWithTitle:@"Edit Your Name" andMessage:nil andCancelButtonTitle:@"Cancel" andOtherTitle:@"Save" andTag:100 andAlertType:UIAlertViewStylePlainTextInput andTextInput:[[[LXSession thisSession] user] name] andIndexPath:nil];
    } else if ([action isEqualToString:@"changeEmail"]) {
        [self permissionsDelegate:@"email"];
    }
}


- (IBAction)rightBarButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}





# pragma mark action sheet delegate

-  (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 50) {
        //image picker
        if (buttonIndex == 0) {
            UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [imagePicker setMediaTypes:@[(NSString*)kUTTypeImage]];
            [imagePicker setAllowsEditing:NO];
            [self presentViewController:imagePicker animated:YES completion:^(void){}];
        } else if (buttonIndex == 1 && buttonIndex != [actionSheet cancelButtonIndex]) {
            UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [imagePicker setMediaTypes:@[(NSString*)kUTTypeImage]];
            [imagePicker setAllowsEditing:NO];
            [self presentViewController:imagePicker animated:YES completion:^(void){}];
        }
    }
}



# pragma mark alert view delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView tag] == 100 && buttonIndex != [alertView cancelButtonIndex]) {
        if ([[alertView textFieldAtIndex:0] text] && [[[alertView textFieldAtIndex:0] text] length] > 0) {
            [[[LXSession thisSession] user] changeName:[[alertView textFieldAtIndex:0] text]];
        } else {
            UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"You can't save a blank name." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [av show];
        }
        [self reloadScreen];
    }
}

- (void) showAlertWithTitle:(NSString*)title andMessage:(NSString*)message andCancelButtonTitle:(NSString*)cancel andOtherTitle:(NSString*)successTitle andTag:(NSInteger)tag andAlertType:(UIAlertViewStyle)alertStyle andTextInput:(NSString*)textInput andIndexPath:(NSIndexPath*)indexPath {
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:successTitle, nil];
    av.alertViewStyle = alertStyle;
    av.delegate = self;
    av.indexPath = indexPath;
    if (alertStyle == UIAlertViewStylePlainTextInput) {
        UITextField* textField = [av textFieldAtIndex:0];
        [textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [textField setText:textInput];
        [textField setFont:[UIFont titleFontWithSize:16.0f]];
    }
    [av setTag:tag];
    [av show];
}



# pragma mark image picker delegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
        // Media is an image
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        [[[LXSession thisSession] user] updateProfilePictureWithImage:image];
        
        if (self.profileImageViewFromCell) {
            [self.profileImageViewFromCell setImage:image];
        }
        
    }
    [picker dismissViewControllerAnimated:NO completion:^(void){}];
}




# pragma mark notification delegate

- (void) askedPermission:(NSNotification*)notification
{
    if ([[[notification userInfo] objectForKey:@"type"] isEqualToString:@"email"]) {
        //NSLog(@"EMAIL CHANGED HERE MEOW");
        [[self.emailLabelFromCell titleLabel] setText:@"verifying..."];
    }
}


@end
