//
//  SHCollaboratorsViewController.m
//  Hippocampus
//
//  Created by Joseph Gill on 9/18/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHCollaboratorsViewController.h"
#import "SHContactTableViewCell.h"

static NSString *contactCellIdentifier = @"SHContactTableViewCell";

@interface SHCollaboratorsViewController ()

@end

@implementation SHCollaboratorsViewController

@synthesize localKey;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSettings];
    [self shouldPromptForAddressBookPermission];
    [self updateButtonStatus];
    [self setupSearch];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setupSettings
{
    [self setTitle];
    
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:60.0f];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [self.tableView registerNib:[UINib nibWithNibName:contactCellIdentifier bundle:nil] forCellReuseIdentifier:contactCellIdentifier];
}

- (void) setupSearch
{
    self.searchResults = [[[LXAddressBook thisBook] allContacts] mutableCopy];
    self.contactsToInvite = [[NSMutableArray alloc] init];
    isSearching = YES;
    [self.searchBar becomeFirstResponder];
}

- (void) setTitle
{
    if ([self bucket]) {
        [self setTitle:@"Add Collaborators"];
    }
}


# pragma mark helpers

- (NSMutableDictionary*) bucket
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}



# pragma mark table view delegate

- (void) reloadScreen
{
    [self setTitle];
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tV
{
    self.sections = [[NSMutableArray alloc] init];
    [self.sections addObject:@"collaborators"];
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tV numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"collaborators"]) {
        if (isSearching) {
            return self.searchResults.count;
        } else {
            return [[[LXAddressBook thisBook] allContacts] count];
        }
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborators"]) {
        return [self tableView:tV contactCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tV contactCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHContactTableViewCell* cell = (SHContactTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:contactCellIdentifier forIndexPath:indexPath];
    NSMutableDictionary *contact;
    if (isSearching) {
        contact = [self.searchResults objectAtIndex:indexPath.row];
    } else {
        contact = [[[LXAddressBook thisBook] allContacts] objectAtIndex:indexPath.row];
    }
    [cell configureWithContact:contact andSelectedContacts:self.contactsToInvite];
    [cell layoutIfNeeded];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborators"]) {
        return 60.0f;
    }
    return 44.0f;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"collaborators"]) {
        [self addOrRemoveContactAtIndexPath:indexPath];
        [self updateButtonStatus];
    }
}

# pragma mark - Address Book

- (void) shouldPromptForAddressBookPermission
{
    if (![[LXAddressBook thisBook] permissionDetermined]) {
        [[LXAddressBook thisBook] requestAccess:^(BOOL success){
            [self reloadScreen];
        }];
    }
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

- (void) addOrRemoveContactAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *contact = isSearching ? [self.searchResults objectAtIndex:indexPath.row] : [[[LXAddressBook thisBook] allContacts] objectAtIndex:indexPath.row];
    if ([self.contactsToInvite containsObject:contact]) {
        [self.contactsToInvite removeObject:contact];
    } else {
        [self.contactsToInvite addObject:contact];
    }
    [(SHContactTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath] selectedContact];
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


# pragma  mark - AlertView Delegate

- (void) alertBeforeSendingInvites
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Invite Collaborators?"
                                                     message:[NSString stringWithFormat:@"Are you sure you want to share this bucket with %@", [self.contactsToInvite namesOfContacts]]
                                                    delegate:self
                                           cancelButtonTitle:@"No"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Yes"];
    [alert setTag:2];
    [alert show];
}

- (void) alertForFailure
{
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Sorry"
                                                     message:@"We were unable to invite your collaborators."
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles: nil];
    [alert setTag:3];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 2 && alertView.cancelButtonIndex != buttonIndex) {
        [[self bucket] addCollaboratorsWithContacts:self.contactsToInvite
                                    success:^(id responseObject){
                                        [self dismissViewControllerAnimated:YES completion:^(void){}];
                                    }failure:^(NSError *error) {
                                        [self alertForFailure];
                                    }
         ];
    } else if (alertView.tag == 3) {
        [self dismissViewControllerAnimated:YES completion:^(void){}];
    }
}

# pragma mark - Actions
- (IBAction)inviteAction:(id)sender {
    [self alertBeforeSendingInvites];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}
@end
