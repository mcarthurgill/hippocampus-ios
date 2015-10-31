//
//  SHAssignBucketsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHAssignBucketsViewController.h"
#import "SHAssignBucketTableViewCell.h"
#import "SHLoadingTableViewCell.h"
#import "SHSearch.h"
#import "NSArray+Attributes.h"

static NSString *assignCellIdentifier = @"SHAssignBucketTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";

@interface SHAssignBucketsViewController ()

@end

@implementation SHAssignBucketsViewController

@synthesize localKey;

@synthesize searchBar;
@synthesize tableView;

@synthesize sections;
@synthesize bucketResultKeys;
@synthesize bucketSelectedKeys;
@synthesize contactsSelected;

@synthesize topViewLabel;
@synthesize topView;

@synthesize topInputView;
@synthesize bucketTextField;
@synthesize inputActionButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bucketSelectedKeys = [[NSMutableArray alloc] init];
    self.bucketResultKeys = [[NSMutableArray alloc] init];
    self.contactsSelected = [[NSMutableArray alloc] init];
    
    [self setupSettings];
    [self determineSelectedKeys];
    
    [self reloadScreen];
    
    [self.topInputView setHidden:YES];
    [self.bucketTextField setFont:[UIFont titleFontWithSize:15.0f]];
    [self.bucketTextField setTextColor:[UIColor SHFontDarkGray]];
    
    [[self.inputActionButton titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedBucketLocalKeys:) name:@"updatedBucketLocalKeys" object:nil];
    
    if ([self shouldOpenOnSearchKeyboard]) {
        [self.searchBar performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.01];
    }
    
    [self prePermissionsDelegate:@"contacts" message:@"Assigning thoughts is simple when choosing a contact from your address book."];
}

- (BOOL) shouldOpenOnSearchKeyboard
{
    return YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) setTitle
{
    [self setTitle:[NSString stringWithFormat:@"Assign Buckets%@", ([[self bucketSelectedKeys] count] > 0 ? [NSString stringWithFormat:@" (%lu)", (unsigned long)[[self bucketSelectedKeys] count]] : @"")]];
}

- (void) setupSettings
{
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:70.0f];
    
    [self.tableView registerNib:[UINib nibWithNibName:assignCellIdentifier bundle:nil] forCellReuseIdentifier:assignCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.topViewLabel setFont:[UIFont titleFontWithSize:15.0f]];
    [self.topViewLabel setTextColor:[UIColor SHFontDarkGray]];
    [self.topViewLabel setText:@"New Bucket"];
    
    [self.topView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.searchBar.layer.borderWidth = 1.0f;
    self.searchBar.layer.borderColor = [UIColor slightBackgroundColor].CGColor;
    
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}




# pragma mark helpers

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}

- (NSArray*) bucketKeys
{
    if ([self.searchBar text] && [[self.searchBar text] length] > 0)
        return [[[SHSearch defaultManager] getCachedObjects:@"bucketKeys" withTerm:[self.searchBar text]] ignoringObjects:self.bucketSelectedKeys];
    return [[LXObjectManager objectWithLocalKey:@"bucketLocalKeys"] ignoringObjects:self.bucketSelectedKeys];
}

- (NSArray*) contacts
{
    if ([self.searchBar text] && [[self.searchBar text] length] > 0)
        return [[[SHSearch defaultManager] getCachedObjects:@"contacts" withTerm:[self.searchBar text]] removeContacts:self.contactsSelected];
    return [[[LXAddressBook thisBook] contactsForAssignment] removeContacts:self.contactsSelected];
}

- (NSArray*) recent
{
    if ([NSMutableDictionary recentBucketLocalKeys])
        return [[NSMutableDictionary recentBucketLocalKeys] ignoringObjects:self.bucketSelectedKeys];
    return nil;
}

- (NSMutableDictionary*) bucketAtIndexPath:(NSIndexPath*)indexPath
{
    return [LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
}

- (void) determineSelectedKeys
{
    for (NSMutableDictionary* bucketStub in [[self item] bucketsArray]) {
        [self.bucketSelectedKeys addObject:[bucketStub localKey]];
    }
}

- (void) addKeyToSelected:(NSString*)key
{
    if (![self.bucketSelectedKeys containsObject:key]) {
        [self.bucketSelectedKeys addObject:key];
    }
    if ([LXObjectManager objectWithLocalKey:key] && [[LXObjectManager objectWithLocalKey:key] objectForKey:@"for_deselect"]) {
        [self addContactToSelected:[[LXObjectManager objectWithLocalKey:key] objectForKey:@"for_deselect"]];
    }
}

- (void) removeKeyFromSelected:(NSString*)key
{
    [self.bucketSelectedKeys removeObject:key];
    if ([LXObjectManager objectWithLocalKey:key] && [[LXObjectManager objectWithLocalKey:key] objectForKey:@"for_deselect"]) {
        [self removeContactFromSelected:[[LXObjectManager objectWithLocalKey:key] objectForKey:@"for_deselect"]];
    }
}

- (void) addContactToSelected:(NSMutableDictionary*)contact
{
    if (![self.contactsSelected containsObject:contact]) {
        [self.contactsSelected addObject:contact];
    }
}

- (void) removeContactFromSelected:(NSMutableDictionary*)contact
{
    [self.contactsSelected removeObject:contact];
}




# pragma mark table view delegate

- (void) reloadScreen
{
    //deselect all rows
    for (NSIndexPath* selectedPath in [self.tableView indexPathsForSelectedRows]) {
        [self.tableView deselectRowAtIndexPath:selectedPath animated:NO];
    }
    [self.tableView reloadData];
    for (NSIndexPath* indexPath in [self indexPathsForKeys]) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [self setTitle];
}

- (NSMutableArray*) indexPathsForKeys
{
    NSMutableArray* tempPaths = [[NSMutableArray alloc] init];
    NSInteger inSection = [self.sections indexOfObject:@"other"];
    NSInteger i = 0;
    for (NSString* key in self.bucketSelectedKeys) {
        NSInteger index = [[self bucketKeys] indexOfObject:key];
        if (index != NSNotFound) {
            [tempPaths addObject:[NSIndexPath indexPathForRow:[[self bucketKeys] indexOfObject:key] inSection:inSection]];
        }
        if ([self.sections containsObject:@"selected"])
        {
            [tempPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        ++i;
    }
    return tempPaths;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if ([self.bucketSelectedKeys count] > 0) {
        [self.sections addObject:@"selected"];
    }
    if ([self recent] && [[self recent] count] > 0 && ![self searchActivated]) {
        [self.sections addObject:@"recent"];
    }
    if ([self bucketKeys] && [[self bucketKeys] count] > 0) {
        [self.sections addObject:@"other"];
    }
    if ([self contacts] && [[self contacts] count] > 0) {
        [self.sections addObject:@"contacts"];
    }
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"selected"]) {
        return [self.bucketSelectedKeys count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"recent"]) {
        return [[self recent] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"other"]) {
        return [[self bucketKeys] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"contacts"]) {
        return [[self contacts] count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        if ([LXObjectManager objectWithLocalKey:[[self recent] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[[self recent] objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"]) {
        if ([LXObjectManager objectWithLocalKey:[[self bucketSelectedKeys] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[[self bucketSelectedKeys] objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"other"]) {
        if ([LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[[self bucketKeys] objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contacts"]) {
        return [self tableView:tV contactCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tV bucketCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHAssignBucketTableViewCell* cell = (SHAssignBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:assignCellIdentifier];
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"]) {
        [cell configureWithBucketLocalKey:[self.bucketSelectedKeys objectAtIndex:indexPath.row]];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        [cell configureWithBucketLocalKey:[[self recent] objectAtIndex:indexPath.row]];
    } else {
        [cell configureWithBucketLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
    }
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV contactCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHAssignBucketTableViewCell* cell = (SHAssignBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:assignCellIdentifier];
    [cell configureWithContact:[[self contacts] objectAtIndex:indexPath.row]];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    [cell configureWithResponseObject:[@{@"local_key":([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.bucketSelectedKeys objectAtIndex:indexPath.row] : [[self bucketKeys] objectAtIndex:indexPath.row])} mutableCopy]];
    [cell invertIfUpsideDown];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self endEditing];
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"contacts"]) {
        NSMutableDictionary* newBucket = [NSMutableDictionary create:@"bucket"];
        [newBucket setObject:[[[self contacts] objectAtIndex:indexPath.row] objectForKey:@"name"] forKey:@"first_name"];
        [newBucket setObject:[@{@"object_type":@"contact_card", @"contact_details":[[self contacts] objectAtIndex:indexPath.row]} mutableCopy] forKey:@"contact_card"];
        [newBucket setObject:[[self contacts] objectAtIndex:indexPath.row] forKey:@"for_deselect"];
        [newBucket assignLocalVersionIfNeeded:YES];
        [self addKeyToSelected:[newBucket localKey]];
        [self reloadScreen];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        [self addKeyToSelected:[[self recent] objectAtIndex:indexPath.row]];
    } else {
        [self addKeyToSelected:([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.bucketSelectedKeys objectAtIndex:indexPath.row] : [[self bucketKeys] objectAtIndex:indexPath.row])];
    }
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    [self reloadScreen];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"recent"]) {
        [self removeKeyFromSelected:[[self recent] objectAtIndex:indexPath.row]];
    } else {
        [self removeKeyFromSelected:([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.bucketSelectedKeys objectAtIndex:indexPath.row] : [[self bucketKeys] objectAtIndex:indexPath.row])];
    }
    [self reloadScreen];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    [self endEditing];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
}




# pragma mark section headers

- (NSString*) tableView:(UITableView *)tV titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"selected"]) {
        return @"Assigned to:";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"recent"]) {
        return @"Recent";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"other"]) {
        return @"Buckets";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"contacts"]) {
        return @"Contacts";
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






# pragma mark user actions

- (IBAction)leftButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^(void){}];
}

- (IBAction)rightButtonAction:(id)sender
{
    [[self item] updateBucketsWithLocalKeys:self.bucketSelectedKeys success:^(id responseObject){} failure:^(NSError* error){}];
    //dismiss
    [self dismissViewControllerAnimated:NO completion:^(void){}];
}

- (IBAction)topViewButtonAction:(id)sender
{
    [self beginEditing];
}





# pragma mark search bar delegate

- (void) searchBar:(UISearchBar *)bar textDidChange:(NSString *)searchText
{
    if ([LXServer hasInternetConnection]) {
        [[SHSearch defaultManager] remoteBucketSearchWithTerm:[bar text] hitsPerPage:16
                                                      success:^(id responseObject) {
                                                          [self reloadScreen];
                                                      }
                                                      failure:^(NSError* error) {
                                                      }
         ];
    } else {
        [[SHSearch defaultManager] localBucketSearchWithTerm:[bar text]
                                                     success:^(id responseObject) {
                                                         [self reloadScreen];
                                                     }
                                                     failure:^(NSError* error) {
                                                     }
         ];
    }
    [[SHSearch defaultManager] contactsSearchWithTerm:[bar text]
                                                 success:^(id responseObject) {
                                                     [self reloadScreen];
                                                 }
                                                 failure:^(NSError* error) {
                                                 }
     ];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self endEditing];
}

- (BOOL) searchActivated
{
    return [self.searchBar text] && [[self.searchBar text] length] > 0;
}




# pragma mark new bucket

- (void) beginEditing
{
    [self.topView setHidden:YES];
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
        if (self.searchBar.text && self.searchBar.text.length > 0){
            [self.bucketTextField setText:self.searchBar.text];
        }
    }
    [self.topInputView setHidden:NO];
    [self.bucketTextField becomeFirstResponder];
    [self.tableView setAlpha:0.3f];
    [self.searchBar setAlpha:0.3f];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
}

- (void) endEditing
{
    [self.topView setHidden:NO];
    if ([self.bucketTextField isFirstResponder]) {
        [self.bucketTextField resignFirstResponder];
    }
    [self.topInputView setHidden:YES];
    [self.tableView setAlpha:1.0f];
    [self.searchBar setAlpha:1.0f];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self captureBucketAndEnd];
    return YES;
}

- (IBAction)inputAction:(id)sender
{
    [self captureBucketAndEnd];
}

- (void) captureBucketAndEnd
{
    if ([self.bucketTextField text] && [[self.bucketTextField text] length] > 0) {
        [self addBucketWithText:[self.bucketTextField text]];
    }
    [self.bucketTextField setText:@""];
    [self endEditing];
}

- (void) addBucketWithText:(NSString*)text
{
    //CREATE BUCKET
    NSMutableDictionary* newBucket = [NSMutableDictionary create:@"bucket"];
    [newBucket setObject:text forKey:@"first_name"];
    [newBucket assignLocalVersionIfNeeded:YES];
    [self addKeyToSelected:[newBucket localKey]];
    [self reloadScreen];
}




# pragma mark notifications

- (void) updatedBucketLocalKeys:(NSNotification*)notification
{
    [self reloadScreen];
}

@end
