//
//  HCBucketViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/3/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCBucketViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "HCContainerViewController.h"

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
    
    //remove extra cell lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setupProperties];
    
    [self.navigationItem setTitle:[self.bucket objectForKey:@"first_name"]];
    [self setupConstraint];
    [self observeKeyboard];
    
    [self refreshChange];
    
    [self setTableScrollToIndex:([self currentArray].count) animated:NO];
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
    shouldContinueRequesting = YES;
    [self setScrollToBottom:YES];
    [composeTextView setScrollEnabled:NO];
    [composeTextView.layer setCornerRadius:4.0f];
    [self setPage:0];
    self.allItems = [[NSMutableArray alloc] init];
}

//- (void) setupRefreshControl {
//    UITableViewController *tableViewController = [[UITableViewController alloc] init];
//    tableViewController.tableView = self.tableView;
//    
//    self.refreshControl = [[UIRefreshControl alloc] init];
//    [self.refreshControl addTarget:self action:@selector(refreshChange) forControlEvents:UIControlEventValueChanged];
//    tableViewController.refreshControl = self.refreshControl;
//}

#pragma mark - Table view data source

- (void) reloadScreenToIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
    [self setTableScrollToIndex:index animated:animated];
    [self toggleSaveButton];
}

- (void) setTableScrollToIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index >= [[self currentArray] count]) {
        --index;
    }
    if ([self currentArray].count > 0 && index < [self currentArray].count) {
        NSIndexPath *ipath = [NSIndexPath indexPathForRow:index inSection: 0];
        if (self.scrollToBottom) {
            [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: animated];
        } else {
            [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionTop animated: animated];
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
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"])
    {
        if ([[self currentArray] respondsToSelector:@selector(count)]) {
            return [[self currentArray] count];
        }
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        [self shouldRequestMoreItems];
        return [self itemCellForTableView:self.tableView withItem:[[self currentArray] objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    UIFont* font = note.font;
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[[item objectForKey:@"message"] truncated:320] width:width font:font])];
    [note setFont:font];
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
        NSDictionary* item = [[self currentArray] objectAtIndex:indexPath.row];
        int additional = 0;
        if ([item objectForKey:@"media_urls"]) {
            additional = (PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*[[item objectForKey:@"media_urls"] count];
        }
        return [self heightForText:[[item objectForKey:@"message"] truncated:320] width:280.0f font:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f]] + 22.0f + 12.0f + 14.0f + additional;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        //HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
        [itvc setItem:[[self currentArray] objectAtIndex:indexPath.row]];
        [itvc setItems:[self currentArray]];
        [itvc setBucket:self.bucket];
        [itvc setDelegate:self];
        [self setScrollToBottom:NO];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
            NSDictionary* object = [[self currentArray] objectAtIndex:indexPath.row];
            [self deleteItem:object];
            [[self allItems] removeObject:object];
            [self reloadScreenToIndex:indexPath.row animated:YES];
        }
    }
}


# pragma  mark actions

- (IBAction)addAction:(id)sender
{
    if (self.composeTextView.text.length > 0) {
        NSMutableDictionary* tempNote = [[NSMutableDictionary alloc] init];
        
        [tempNote setObject:self.composeTextView.text forKey:@"message"];
        [tempNote setObject:@"once" forKey:@"item_type"];
        
        if ([self.bucket objectForKey:@"id"] && [[self.bucket objectForKey:@"id"] integerValue] && [[self.bucket objectForKey:@"id"] integerValue] > 0) {
            [tempNote setObject:[self.bucket objectForKey:@"id"] forKey:@"bucket_id"];
            [tempNote setObject:@"assigned" forKey:@"status"];
        }
        
        

//        [self addItemToTable:responseBlock];
//        [self reloadScreenToIndex:[self currentArray].count animated:YES];
//        [self clearTextField];
    }
}

- (void) addItemToTable:(NSDictionary *)item {
    [self.allItems addObject:item];
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
    if (NULL_TO_NIL([self.bucket objectForKey:@"id"]) && [[self.bucket objectForKey:@"id"] integerValue] > 0) {
        [self sendRequestForBucketShow];
    } else {
        [self sendRequestForAllItems];
    }
}

- (void) sendRequestForBucketShow
{
    [self sendRequestForBucketShowWithPage:self.page];
}

- (void) sendRequestForBucketShowWithPage:(int)p
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", [self.bucket objectForKey:@"id"]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
                           success:^(id responseObject) {
                               NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                                                      NSMakeRange(0,[[responseObject objectForKey:@"items"] count])];
                               if (indexes.count == 0) {
                                   shouldContinueRequesting = NO;
                                   if ([[responseObject objectForKey:@"items"] count] > 0) {
                                       self.allItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
                                   }
                                   //SAVE ITEMS TO DISK HERE
                               } else {
                                   [self.allItems insertObjects:[responseObject objectForKey:@"items"] atIndexes:indexes];
                               }
                               requestMade = NO;
                               [self setScrollToBottom:NO];
                               if ([[responseObject objectForKey:@"items"] count] > 0) {
                                   [self reloadScreenToIndex:indexes.count animated:NO];
                               }
                               [self clearTextField];
                               if ([[responseObject objectForKey:@"items"] count] > 0) {
                                   [self incrementPage];
                               }
                               [self saveBucket];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               //[self reloadScreenToIndex:[self currentArray].count animated:NO];
                           }
     ];
}

- (void) sendRequestForAllItems
{
    [self sendRequestForAllItemsWithPage:self.page];
}

- (void) sendRequestForAllItemsWithPage:(int)p
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"items"]) {
                                   NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                                                          NSMakeRange(0,[[responseObject objectForKey:@"items"] count])];
                                   if (indexes.count == 0) {
                                       shouldContinueRequesting = NO;
                                       if ([[responseObject objectForKey:@"items"] count] > 0) {
                                           self.allItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
                                       }
                                       //SAVE HERE
                                   } else {
                                       [self.allItems insertObjects:[responseObject objectForKey:@"items"] atIndexes:indexes];
                                   }
                                   if ([[responseObject objectForKey:@"items"] count] > 0) {
                                       [self reloadScreenToIndex:indexes.count animated:NO];
                                   }
                               }
                               if ([responseObject objectForKey:@"outstanding_items"] && self.page < 1) {
                                   [self.allItems addObjectsFromArray:[responseObject objectForKey:@"outstanding_items"]];
                                   if ([[responseObject objectForKey:@"outstanding_items"] count] > 0) {
                                       [self reloadScreenToIndex:[self currentArray].count animated:NO];
                                   }
                               }
                               if ([responseObject objectForKey:@"bottom_items"] && [responseObject objectForKey:@"page"]) {
                                   NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                                                          NSMakeRange(0,[[responseObject objectForKey:@"bottom_items"] count])];
                                   if (indexes.count == 0) {
                                       shouldContinueRequesting = NO;
                                   }
                                   [self.allItems insertObjects:[responseObject objectForKey:@"bottom_items"] atIndexes:indexes];
                                   [self setScrollToBottom:NO];
                                   [self reloadScreenToIndex:indexes.count animated:NO];
                               }
                               requestMade = NO;
                               if ([[responseObject objectForKey:@"items"] count] > 0 || [[responseObject objectForKey:@"bottom_items"] count] > 0) {
                                   [self incrementPage];
                               }
                               [self saveBucket];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               //[self reloadScreenToIndex:[self currentArray].count animated:NO];
                           }
     ];
    
}

- (void) shouldRequestMoreItems
{
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
    NSIndexPath *firstRow = [visibleRows firstObject];
    if (firstRow.row == 0 && requestMade == NO && shouldContinueRequesting == YES) {
        [self refreshChange];
    }
}


- (void) deleteItem:(NSDictionary *)item {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [item objectForKey:@"id"]] withMethod:@"DELETE" withParamaters:nil success:^(id responseObject) {} failure:^(NSError* error) {}];
}

- (void) incrementPage {
    self.page = self.page + 1;
}

- (void) updateItemsArrayWithOriginal:(NSMutableDictionary*)original new:(NSMutableDictionary*)n
{
    int index = [self.allItems indexOfObject:original];
    if (index && index < self.allItems.count) {
        [self.allItems replaceObjectAtIndex:index withObject:n];
    }
    [self.tableView reloadData];
}

- (void) scrollToNote:(NSMutableDictionary*)original
{
    int index = [[self currentArray] indexOfObject:original];
    if (index && index < [self currentArray].count) {
        [self setTableScrollToIndex:index animated:NO];
    }
}



# pragma mark helpers

- (NSMutableArray*) currentArray
{
    if (!self.allItems || [self.allItems count] == 0) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:[self currentBucketID]]) {
            return [[NSUserDefaults standardUserDefaults] objectForKey:[self currentBucketID]];
        }
    }
    return self.allItems;
}

- (BOOL) canSaveNote
{
    return self.composeTextView.text && [self.composeTextView.text length] > 0 && [self.composeTextView.textColor isEqual:[UIColor blackColor]];
}

- (void) saveBucket
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self.allItems count] > 0) {
            NSLog(@"array: %@", self.allItems);
            [[NSUserDefaults standardUserDefaults] setObject:[self itemsToSave] forKey:[self currentBucketID]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    });
}

- (NSString*) currentBucketID
{
    return [NSString stringWithFormat:@"%@", [self.bucket objectForKey:@"id"]];
}

- (NSMutableArray*) itemsToSave
{
    NSMutableArray* temp = [[NSMutableArray alloc] init];
    for (NSDictionary* t in self.allItems) {
        [temp addObject:[self cleanDictionary:t]];
    }
    return temp;
}

- (NSMutableDictionary*) cleanDictionary:(NSDictionary*)dictIn
{
    NSMutableDictionary* tDict = [[NSMutableDictionary alloc] initWithDictionary:dictIn];
    NSArray* keys = [tDict allKeys];
    for (NSString* k in keys) {
        if (!NULL_TO_NIL([tDict objectForKey:k])) {
            [tDict removeObjectForKey:k];
        }
        if ([[tDict objectForKey:k] isKindOfClass:[NSString class]]) {
            if (!NULL_TO_NIL([tDict objectForKey:k])) {
                [tDict removeObjectForKey:k];
            }
        } else if ([[tDict objectForKey:k] isKindOfClass:[NSArray class]]) {
            [tDict removeObjectForKey:k];
        } else if ([[tDict objectForKey:k] isKindOfClass:[NSDictionary class]] || [[tDict objectForKey:k] isKindOfClass:[NSMutableDictionary class]]) {
            return [self cleanDictionary:[tDict objectForKey:k]];
        }
    }
    return tDict;
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
    [self setTableScrollToIndex:[self currentArray].count animated:YES];
    
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
    self.tableviewHeightConstraint.constant = self.view.frame.size.height - self.saveButton.frame.size.height;

    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}


# pragma mark Constraints

-(void) setupConstraint {
    self.composeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.composeView];
    
    NSDictionary *views = @{@"view": self.composeView,
                            @"top": self.topLayoutGuide };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[top][view]" options:0 metrics:nil views:views]];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.composeView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.bottomConstraint];
}

@end
