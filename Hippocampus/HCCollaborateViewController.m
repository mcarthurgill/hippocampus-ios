//
//  HCCollaborateViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCCollaborateViewController.h"
#import "HCExplanationTableViewCell.h"
#import "HCCollaborateTableViewCell.h"
#import "HCNameViewController.h"
#import "HCPermissionViewController.h"

@interface HCCollaborateViewController ()

@end

@implementation HCCollaborateViewController

@synthesize tableView;
@synthesize sections;
@synthesize contactsToInvite;
@synthesize searchResults;
@synthesize searchBar;
@synthesize bucket;
@synthesize isCollaborating;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) setup
{
    if (isCollaborating) {
        [self.navigationItem setTitle:@"Invite Collaborators"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(share)];
    } else {
        [self.navigationItem setTitle:@"Add Contact"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addContact)];
    }
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    //[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    [self updateButtonStatus];
    
    self.contactsToInvite = [[NSMutableArray alloc] init];
    self.searchResults = [[NSMutableArray alloc] init];
    isSearching = NO;
    
    [self shouldPromptForAddressBookPermission];
}

#pragma mark - UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    if ([[LXAddressBook thisBook] permissionDetermined] && [[LXAddressBook thisBook] permissionGranted]) {
        [self.sections addObject:@"contacts"];
    } else {
        [self.sections addObject:@"explanation"];
    }
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"contacts"]) {
        return isSearching ? self.searchResults.count : [[[LXAddressBook thisBook] allContacts] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"explanation"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contacts"]) {
        return [self contactsCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return [self explanationCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) explanationCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCExplanationTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"explanationCell" forIndexPath:indexPath];
    [cell configureWithText:@"You must grant location permission create a collaborative collection. Go to Settings > Privacy > Contacts > Hippocampus"];
    return cell;
}

- (UITableViewCell*) contactsCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCCollaborateTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"contactsCell" forIndexPath:indexPath];
    NSDictionary *contact = isSearching ? [self.searchResults objectAtIndex:indexPath.row] : [[[LXAddressBook thisBook] allContacts] objectAtIndex:indexPath.row];
    [cell configureWithContact:contact andSelectedContacts:self.contactsToInvite];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contacts"]) {
        return 55.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return 150.0f;
    }
    
    return 44.0f;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contacts"]) {
        [self addOrRemoveContactAtIndexPath:indexPath];
        [self updateButtonStatus];
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"contacts"]) {
        return @"Contacts";
    }
    return nil;
}


# pragma mark - Sharing

- (void) share
{
    if ([self shouldGetUserName]) {
        [self displayNameController];
    } else {
        [self alertBeforeSendingInvites];
    }
}

- (void) addContact
{
    [self showHUDWithMessage:@"Adding contact"];
    [[LXServer shared] createContactCardWithBucket:self.bucket andContact:[[self.contactsToInvite firstObject] mutableCopy] success:^(id responseObject) {
        [self hideHUD];
        [self showHUDWithMessage:@"Success!"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self hideHUD];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }failure:^(NSError *error) {
        [self hideHUD];
    }];
}

- (void) inviteForCollaboration
{
    [self showHUDWithMessage:@"Adding collaborators"];
    [[LXServer shared] createBucketUserPairsWithContacts:self.contactsToInvite andBucket:self.bucket success:^(id responseObject) {
        [self hideHUD];
        [self showHUDWithMessage:@"Success!"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self hideHUD];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }failure:^(NSError *error) {
        [self hideHUD];
    }];
}

- (void) addOrRemoveContactAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *contact = isSearching ? [self.searchResults objectAtIndex:indexPath.row] : [[[LXAddressBook thisBook] allContacts] objectAtIndex:indexPath.row];
    
    if (isCollaborating) {
        if ([self.contactsToInvite containsObject:contact]) {
            [self.contactsToInvite removeObject:contact];
            [[self.tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
        } else {
            [self.contactsToInvite addObject:contact];
            [[self.tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
    } else {
        if ([self.contactsToInvite containsObject:contact]) {
            [self.contactsToInvite removeObject:contact];
            [[self.tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
        } else {
            for (NSDictionary*contact in self.contactsToInvite) {
                NSIndexPath *ip;
                if (isSearching) {
                    ip = [NSIndexPath indexPathForRow:[self.searchResults indexOfObject:contact] inSection:0];
                } else {
                    ip = [NSIndexPath indexPathForRow:[[[LXAddressBook thisBook] allContacts] indexOfObject:contact] inSection:0];
                }
                [[self.tableView cellForRowAtIndexPath:ip] setAccessoryType:UITableViewCellAccessoryNone];
            }
            [self.contactsToInvite removeAllObjects];
            [self.contactsToInvite addObject:contact];
            [[self.tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
    }
}

- (void) displayNameController
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCNameViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"nameViewController"];
    [vc setDelegate:self];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

# pragma  mark - AlertView Delegate



- (void) alertBeforeSendingInvites
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Are you sure?"
                                                     message:[NSString stringWithFormat:@"Are you sure you want to share this collection with %@", [self.contactsToInvite namesOfContacts]]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Share"];
    [alert setTag:2];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 2 && buttonIndex == 1) {
        [self inviteForCollaboration];
    }
}


# pragma mark - Send Invites Delegate
- (BOOL) shouldGetUserName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return ![userDefaults objectForKey:@"collaborativeThreadCount"];
}

- (void) updateUserShareThreadCount
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults objectForKey:@"collaborativeThreadCount"]) {
        [userDefaults setInteger:1 forKey:@"collaborativeThreadCount"];
        [userDefaults synchronize];
    }
}


# pragma mark - Address Book

- (void) shouldPromptForAddressBookPermission
{
    if (![[LXAddressBook thisBook] permissionDetermined] && ![[LXAddressBook thisBook] alreadyAskedPermission]) {
        [[LXAddressBook thisBook] setAlreadyAskedPermission:YES];
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCPermissionViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"permissionViewController"];
        [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
        [vc setImageForMainImageView:[UIImage imageNamed:@"permission-screen.jpg"]];
        [vc setMainLabelText:@"Use your contacts to build collections with friends."];
        [vc setPermissionType:@"contacts"];
        [vc setDelegate:self];
        [vc setButtonText:@"Grant Contact Permission"];
        [self.navigationController presentViewController:vc animated:NO completion:nil];
    }
}

- (void) permissionsDelegate
{
    [self.tableView reloadData];
}


# pragma mark - Helpers

- (void) updateButtonStatus
{
    if (self.contactsToInvite && self.contactsToInvite.count > 0) {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}


#pragma mark - Search

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    [self.searchResults removeAllObjects];
    
    if (text.length == 0) {
        isSearching = NO;
    } else {
        isSearching = YES;
        NSMutableArray *allContacts = [[LXAddressBook thisBook] allContacts];
        for (NSDictionary* dict in allContacts) {
            NSRange nameRange = [[dict name] rangeOfString:text options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound) {
                [self.searchResults addObject:dict];
            }
        }
    }
    
    [self.tableView reloadData];
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
