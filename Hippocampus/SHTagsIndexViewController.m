//
//  SHTagsIndexViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHTagsIndexViewController.h"
#import "SHAssignTagTableViewCell.h"
#import "SHLoadingTableViewCell.h"
#import "SHSearch.h"
#import "SHNewBucketTableViewCell.h"

static NSString *assignCellIdentifier = @"SHAssignTagTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";
static NSString *newBucketCellIdentifier = @"SHNewBucketTableViewCell";

@interface SHTagsIndexViewController ()

@end

@implementation SHTagsIndexViewController

@synthesize tableView;
@synthesize searchBar;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedTagLocalKeys:) name:@"updatedTagLocalKeys" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadScreen) name:@"refreshTagsViewController" object:nil];
    [self.tableView registerNib:[UINib nibWithNibName:newBucketCellIdentifier bundle:nil] forCellReuseIdentifier:newBucketCellIdentifier];
    
    [self performSelectorOnMainThread:@selector(reloadAndScroll) withObject:nil waitUntilDone:NO];
    [self reloadScreen];
}

- (void) reloadAndScroll
{
    [self reloadScreen];
    if ([self.tableView numberOfRowsInSection:0] > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) setupSettings
{
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:91.0f];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [self.tableView registerNib:[UINib nibWithNibName:assignCellIdentifier bundle:nil] forCellReuseIdentifier:assignCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(64.0f, 0, 0, 0)];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.searchBar.layer.borderWidth = 1.0f;
    self.searchBar.layer.borderColor = [UIColor slightBackgroundColor].CGColor;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self beginningActions];
}

- (void) beginningActions
{
    [NSMutableDictionary tagKeysWithSuccess:nil failure:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




# pragma mark notifications

- (void) updatedTagLocalKeys:(NSNotification*)notification
{
    [self reloadScreen];
}




# pragma mark helpers

- (NSArray*) tagKeys
{
    if ([self.searchBar text] && [[self.searchBar text] length] > 0)
        return [[SHSearch defaultManager] getCachedObjects:@"tagKeys" withTerm:[self.searchBar text]];
    return [LXObjectManager objectWithLocalKey:@"tagLocalKeys"];
}




# pragma mark table view delegate and data source

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"new"];
    [self.sections addObject:@"tags"];
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"tags"]) {
        return [[self tagKeys] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"new"]) {
        return 1;
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"tags"]) {
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
        return [self tableView:tV newCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tV tagCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHAssignTagTableViewCell* cell = (SHAssignTagTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:assignCellIdentifier];
    [cell configureWithTagLocalKey:[[self tagKeys] objectAtIndex:indexPath.row]];
    [cell layoutIfNeeded];
    return cell;
}


- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    [cell configureWithResponseObject:[@{@"local_key":[[self tagKeys] objectAtIndex:indexPath.row]} mutableCopy]];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV newCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHNewBucketTableViewCell* cell = (SHNewBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:newBucketCellIdentifier];
    [[cell titleLabel] setText:@"Add Group"];
    return cell;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    float scrollViewHeight = scrollView.frame.size.height;
    float scrollContentSizeHeight = scrollView.contentSize.height;
    float scrollOffset = scrollView.contentOffset.y;

    if ((NSInteger)scrollOffset == (NSInteger)-64 && [self tagKeys] && [[self tagKeys] count] > 0) {
        
    }
    else if (scrollOffset + scrollViewHeight == scrollContentSizeHeight) {
        // then we are at the end
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
}



# pragma mark section headers

- (NSString*) tableView:(UITableView *)tV titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"tags"]) {
        
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
}

- (BOOL) searchActivated
{
    return [self.searchBar text] && [[self.searchBar text] length] > 0;
}



# pragma mark actions

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"tags"]) {
        NSMutableDictionary* tag = [LXObjectManager objectWithLocalKey:[[self tagKeys] objectAtIndex:indexPath.row]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushTagViewController" object:nil userInfo:@{@"tag":tag}];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"new"]) {
        [self showAlertWithTitle:@"Create New Group" andMessage:nil andCancelButtonTitle:@"Cancel" andOtherTitle:@"Save" andTag:2 andAlertType:UIAlertViewStylePlainTextInput andTextInput:[self.searchBar text] andIndexPath:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}



# pragma mark ui alert view delegate

- (void) showAlertWithTitle:(NSString*)title andMessage:(NSString*)message andCancelButtonTitle:(NSString*)cancel andOtherTitle:(NSString*)successTitle andTag:(NSInteger)tag andAlertType:(UIAlertViewStyle)alertStyle andTextInput:(NSString*)textInput andIndexPath:(NSIndexPath*)indexPath
{
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

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 2) {
        if ([alertView cancelButtonIndex] != buttonIndex && [alertView textFieldAtIndex:0].text && [[alertView textFieldAtIndex:0].text length] > 0) {
            //CREATE TAG
            NSMutableDictionary* newTag = [NSMutableDictionary create:@"tag"];
            [newTag setObject:[alertView textFieldAtIndex:0].text forKey:@"tag_name"];
            [newTag assignLocalVersionIfNeeded:YES];
            [newTag saveRemote];
            [NSMutableDictionary addTagWithKey:[newTag localKey]];
            [self reloadScreen];
        }
    }
}

@end
