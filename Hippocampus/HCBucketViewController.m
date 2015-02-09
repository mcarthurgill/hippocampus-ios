//
//  HCBucketViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/3/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCBucketViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface HCBucketViewController ()

@end

@implementation HCBucketViewController

@synthesize refreshControl;
@synthesize bucket;
@synthesize sections;
@synthesize allItems;
@synthesize addButton;
@synthesize tableView;
@synthesize composeTextView;
@synthesize composeView;
@synthesize saveButton;
@synthesize bottomConstraint;
@synthesize tableviewHeightConstraint;
@synthesize textViewHeightConstraint;
@synthesize scrollToBottom;
@synthesize page;
@synthesize initializeWithKeyboardUp;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupProperties];
    
    [self.navigationItem setTitle:[self.bucket objectForKey:@"first_name"]];
    [self setupConstraint];
    [self observeKeyboard];
    
    [self refreshChange];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self refreshChange];
    //[self reloadScreen];
    [self shouldSetKeyboardAsFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupProperties {
    requestMade = NO;
    self.scrollToBottom = YES;
    [composeTextView setScrollEnabled:NO];
    [composeTextView.layer setCornerRadius:4.0f];
    self.page = 0;
}


#pragma mark - Table view data source

- (void) reloadScreen
{
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
    [self setTableScroll];
    [self toggleSaveButton];
}

- (void) setTableScroll {

    if (self.allItems.count > 0) {
        if (scrollToBottom) {
            NSIndexPath *ipath = [NSIndexPath indexPathForRow: allItems.count-1 inSection: 0];
            [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: NO];
        }
    }
}

- (void) toggleSaveButton
{
    if ([self canSaveNote]) {
        [self.saveButton setEnabled:YES];
    } else {
        [self.saveButton setEnabled:NO];
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    
    [self.sections addObject:@"all"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return self.allItems.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        return [self itemCellForTableView:self.tableView withItem:[self.allItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[[item objectForKey:@"message"] truncated:320] width:width font:note.font])];
    [note setText:[[item objectForKey:@"message"] truncated:320]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    
    UILabel* blueDot = (UILabel*) [cell.contentView viewWithTag:4];
    
    if ([[item objectForKey:@"status"] isEqualToString:@"outstanding"]) {
        [blueDot.layer setCornerRadius:4];
        [blueDot setClipsToBounds:YES];
        [blueDot setHidden:NO];
    } else {
        [blueDot setHidden:YES];
    }

    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:3];
    [timestamp setText:[NSString stringWithFormat:@"%@%@", (NULL_TO_NIL([item objectForKey:@"buckets_string"]) ? [NSString stringWithFormat:@"%@ - ", [item objectForKey:@"buckets_string"]] : @""), [NSDate timeAgoInWordsFromDatetime:[item objectForKey:@"created_at"]]]];
    
    int i = 0;
    while ([cell.contentView viewWithTag:(200+i)]) {
        [[cell.contentView viewWithTag:(200+i)] removeFromSuperview];
        ++i;
    }
    
    if ([item objectForKey:@"media_urls"] && [[item objectForKey:@"media_urls"] count] > 0) {
        int j = 0;
        for (NSString* url in [item objectForKey:@"media_urls"]) {
            UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, note.frame.origin.y+note.frame.size.height+PICTURE_MARGIN_TOP+(PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*j, 280, PICTURE_HEIGHT)];
            [iv setTag:(200+j)];
            [iv setContentMode:UIViewContentModeScaleAspectFill];
            [iv setClipsToBounds:YES];
            [iv.layer setCornerRadius:8.0f];
            [SGImageCache getImageForURL:url thenDo:^(UIImage* image) {
                if (image) {
                    iv.image = image;
                }
            }];
            [cell.contentView addSubview:iv];
            ++j;
        }
    }
    
    //NSLog(@"INFO ON ITEM:\n%@\n%@\n%@", item.message, item.itemID, item.bucketID);
    return cell;
}

- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    if (!text || [text length] == 0) {
        return 0.0f;
    }
    NSDictionary *attributes = @{NSFontAttributeName: font};
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, 100000)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    return rect.size.height;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        NSDictionary* item = [self.allItems objectAtIndex:indexPath.row];
        int additional = 0;
        if ([item objectForKey:@"media_urls"]) {
            additional = (PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*[[item objectForKey:@"media_urls"] count];
        }
        return [self heightForText:[[item objectForKey:@"message"] truncated:320] width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f + 14.0f + additional;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        self.scrollToBottom = NO;
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
            NSDictionary* object = [[self allItems] objectAtIndex:indexPath.row];
            [self deleteItem:object];
            [[self allItems] removeObject:object];
            [self reloadScreen];
        }
    }
}


# pragma  mark actions

- (IBAction)addAction:(id)sender
{
    if (self.composeTextView.text.length > 0) {
        HCItem* item = [[HCItem alloc] create];
        [item setMessage:self.composeTextView.text];
        [item setItemType:@"once"];
        if (NULL_TO_NIL([self.bucket objectForKey:@"id"])) {
            [item setBucketID:[[self.bucket objectForKey:@"id"] stringValue]];
            [item setStatus:@"assigned"];
        }

        [item saveWithSuccess:^(id responseBlock) {
            NSLog(@"SUCCESS! %@", responseBlock);
            [self refreshChange];
            [self clearTextField];
        }
                      failure:^(NSError *error) {
                          NSLog(@"Error! %@", [error localizedDescription]);
                      }
         ];
    }
}


- (IBAction)refreshControllerChanged:(id)sender
{
    if (self.refreshControl.isRefreshing) {
        //Make server call here.
        [self refreshChange];
    }
}


- (void) refreshChange
{
    if (requestMade)
        return;
    requestMade = YES;
    if (NULL_TO_NIL([self.bucket objectForKey:@"id"])) {
        [self sendRequestForBucketShow];
    } else {
        [self sendRequestForAllItems];
    }
}

- (void) sendRequestForBucketShow {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", [self.bucket objectForKey:@"id"]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", self.page]}
                           success:^(id responseObject) {
                               self.allItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
//                               self.page = (int)[responseObject objectForKey:@"page"];
                               requestMade = NO;
                               [self reloadScreen];
                               [self clearTextField];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               [self reloadScreen];
                           }
     ];
}

- (void) sendRequestForAllItems {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", self.page]}
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"items"]) {
                                   self.allItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
                               }
                               if ([responseObject objectForKey:@"outstanding_items"]) {
                                   [self.allItems addObjectsFromArray:[responseObject objectForKey:@"outstanding_items"]];
                               }
                               if ([responseObject objectForKey:@"bottom_items"] && [responseObject objectForKey:@"page"]) {
                                   //add to bottom of all Items & refresh!
                                   if (self.allItems.count%64==0 && self.allItems.count <= 64*[[responseObject objectForKey:@"page"] integerValue]) {
                                       [self.allItems addObjectsFromArray:[responseObject objectForKey:@"bottom_items"]];
                                   }
                               }
                               requestMade = NO;
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               [self reloadScreen];
                           }
     ];

}

- (void) deleteItem:(NSDictionary *)item {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [item objectForKey:@"id"]] withMethod:@"DELETE" withParamaters:nil success:^(id responseObject) {} failure:^(NSError* error) {}];
}




# pragma mark helpers

- (BOOL) canSaveNote
{
    return self.composeTextView.text && [self.composeTextView.text length] > 0 && [self.composeTextView.textColor isEqual:[UIColor blackColor]];
}




# pragma mark Textview

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"Add Note"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Add Note";
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

- (void) textViewDidChange:(UITextView *)textView
{
    [self toggleSaveButton];
}

- (void) clearTextField {
    self.composeTextView.text = @"Add Note";
    self.composeTextView.textColor = [UIColor lightGrayColor];
    [self.composeTextView resignFirstResponder];
}


- (void) shouldSetKeyboardAsFirstResponder {
    if (self.initializeWithKeyboardUp) {
        [self.composeTextView becomeFirstResponder];
    }
}

# pragma mark Keyboard Notifications

- (void) observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void) keyboardWillShow:(NSNotification *)sender {
    self.scrollToBottom = YES;
    [self setTableScroll];
    
    NSDictionary *info = [sender userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect frame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    self.bottomConstraint.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    
    //for buckets where tableview.contentSize is small
    if (self.tableView.contentSize.height < (self.tableviewHeightConstraint.constant - frame.size.height)) {
        self.tableviewHeightConstraint.constant = self.tableviewHeightConstraint.constant - frame.size.height;
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}


- (void) keyboardWillHide:(NSNotification *)sender {
    NSDictionary *info = [sender userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.bottomConstraint.constant = 0;

    //for buckets where tableview.contentSize is small
    self.tableviewHeightConstraint.constant = self.view.frame.size.height - self.composeView.frame.size.height;

    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}


# pragma mark Constraints

-(void) setupConstraint {
    self.composeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.self.composeView];
    
    NSDictionary *views = @{@"view": self.composeView,
                            @"top": self.topLayoutGuide };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[top][view]" options:0 metrics:nil views:views]];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.composeView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.bottomConstraint];
}

@end
