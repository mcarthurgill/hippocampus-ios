//
//  SHAssignTagsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHAssignTagsViewController.h"
#import "SHAssignTagTableViewCell.h"
#import "SHLoadingTableViewCell.h"
#import "SHSearch.h"
#import "NSArray+Attributes.h"

static NSString *assignCellIdentifier = @"SHAssignTagTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";

@interface SHAssignTagsViewController ()

@end

@implementation SHAssignTagsViewController

@synthesize localKey;

@synthesize searchBar;
@synthesize tableView;

@synthesize sections;
@synthesize tagResultKeys;
@synthesize tagSelectedKeys;

@synthesize topViewLabel;
@synthesize topView;

@synthesize topInputView;
@synthesize bucketTextField;
@synthesize inputActionButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tagSelectedKeys = [[NSMutableArray alloc] init];
    self.tagResultKeys = [[NSMutableArray alloc] init];
    
    [self setupSettings];
    [self determineSelectedKeys];
    
    [self reloadScreen];
    
    [self.topInputView setHidden:YES];
    [self.bucketTextField setFont:[UIFont titleFontWithSize:15.0f]];
    [self.bucketTextField setTextColor:[UIColor SHFontDarkGray]];
    
    [[self.inputActionButton titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedTagLocalKeys:) name:@"updatedTagLocalKeys" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadScreen) name:@"refreshTagsViewController" object:nil];
    
    if ([self shouldOpenOnSearchKeyboard]) {
        [self.searchBar performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.01];
    }
    
    [NSMutableDictionary tagKeysWithSuccess:nil failure:nil];
}

- (BOOL) shouldOpenOnSearchKeyboard
{
    return NO;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) setTitle
{
    [self setTitle:[NSString stringWithFormat:@"Assign Tags%@", ([[self tagSelectedKeys] count] > 0 ? [NSString stringWithFormat:@" (%lu)", (unsigned long)[[self tagSelectedKeys] count]] : @"")]];
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
    [self.topViewLabel setText:@"New Tag"];
    
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

- (NSMutableDictionary*) bucket
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}

- (NSArray*) tagKeys
{
    if ([self.searchBar text] && [[self.searchBar text] length] > 0)
        return [[[SHSearch defaultManager] getCachedObjects:@"tagKeys" withTerm:[self.searchBar text]] ignoringObjects:self.tagSelectedKeys];
    return [[LXObjectManager objectWithLocalKey:@"tagLocalKeys"] ignoringObjects:self.tagSelectedKeys];
}

- (NSMutableDictionary*) bucketAtIndexPath:(NSIndexPath*)indexPath
{
    return [LXObjectManager objectWithLocalKey:[[self tagKeys] objectAtIndex:indexPath.row]];
}

- (void) determineSelectedKeys
{
    for (NSMutableDictionary* tag in [[self bucket] tagsArray]) {
        [self.tagSelectedKeys addObject:[tag localKey]];
    }
}

- (void) addKeyToSelected:(NSString*)key
{
    if (![self.tagSelectedKeys containsObject:key]) {
        [self.tagSelectedKeys addObject:key];
    }
}

- (void) removeKeyFromSelected:(NSString*)key
{
    [self.tagSelectedKeys removeObject:key];
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
    for (NSString* key in self.tagSelectedKeys) {
        NSInteger index = [[self tagKeys] indexOfObject:key];
        if (index != NSNotFound) {
            [tempPaths addObject:[NSIndexPath indexPathForRow:[[self tagKeys] indexOfObject:key] inSection:inSection]];
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
    
    if ([self.tagSelectedKeys count] > 0) {
        [self.sections addObject:@"selected"];
    }
    if ([self tagKeys] && [[self tagKeys] count] > 0) {
        [self.sections addObject:@"other"];
    }
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"selected"]) {
        return [self.tagSelectedKeys count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"other"]) {
        return [[self tagKeys] count];
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"]) {
        if ([LXObjectManager objectWithLocalKey:[[self tagSelectedKeys] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV tagCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[[self tagSelectedKeys] objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"other"]) {
        if ([LXObjectManager objectWithLocalKey:[[self tagKeys] objectAtIndex:indexPath.row]]) {
            return [self tableView:tV tagCellForRowAtIndexPath:indexPath];
        } else {
            [[LXObjectManager defaultManager] refreshObjectWithKey:[[self tagKeys] objectAtIndex:indexPath.row]
                                                           success:^(id responseObject){
                                                               //[self.tableView reloadData];
                                                           } failure:nil
             ];
            return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
        }
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tV tagCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHAssignTagTableViewCell* cell = (SHAssignTagTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:assignCellIdentifier];
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"]) {
        [cell configureWithTagLocalKey:[self.tagSelectedKeys objectAtIndex:indexPath.row]];
    } else {
        [cell configureWithTagLocalKey:[[self tagKeys] objectAtIndex:indexPath.row]];
    }
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    [cell configureWithResponseObject:[@{@"local_key":([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.tagSelectedKeys objectAtIndex:indexPath.row] : [[self tagKeys] objectAtIndex:indexPath.row])} mutableCopy]];
    [cell invertIfUpsideDown];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self endEditing];
    [self addKeyToSelected:([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.tagSelectedKeys objectAtIndex:indexPath.row] : [[self tagKeys] objectAtIndex:indexPath.row])];
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    [self reloadScreen];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeKeyFromSelected:([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"selected"] ? [self.tagSelectedKeys objectAtIndex:indexPath.row] : [[self tagKeys] objectAtIndex:indexPath.row])];
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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"other"]) {
        return @"Tags";
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
    [[self bucket] updateTagsWithLocalKeys:self.tagSelectedKeys success:^(id responseObject){} failure:^(NSError* error){}];
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
    [[SHSearch defaultManager] localTagSearchWithTerm:[bar text]
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
    NSMutableDictionary* newTag = [NSMutableDictionary create:@"tag"];
    [newTag setObject:text forKey:@"tag_name"];
    [newTag assignLocalVersionIfNeeded:YES];
    [self addKeyToSelected:[newTag localKey]];
    [self reloadScreen];
}




# pragma mark notifications

- (void) updatedTagLocalKeys:(NSNotification*)notification
{
    [self reloadScreen];
}

@end
