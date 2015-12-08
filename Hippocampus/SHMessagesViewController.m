//
//  SHMessagesViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/18/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHMessagesViewController.h"
#import "SHItemTableViewCell.h"
#import "SHLoadingTableViewCell.h"
#import "SHItemViewController.h"
#import "SHEditBucketViewController.h"
#import "UIImage+Helpers.h"

#import "SHNudgeSetView.h"

#define PAGE_COUNT 64
#define MAX_TEXTVIEW_HEIGHT 140

static NSString *itemCellIdentifier = @"SHItemTableViewCell";
static NSString *loadingCellIdentifier = @"SHLoadingTableViewCell";
static NSString *itemViewControllerIdentifier = @"SHItemViewController";

static NSString *editBucketIdentifier = @"SHEditBucketViewController";

@interface SHMessagesViewController ()

@end

@implementation SHMessagesViewController

@synthesize localKey;

@synthesize shouldReload;
@synthesize currentlyCellSwiping;

@synthesize blankItem;

@synthesize tableView;
@synthesize inputToolbar;
@synthesize textView;
@synthesize toolbarBottomConstraint;
@synthesize textViewHeightConstraint;
@synthesize inputControlToolbarHeightConstraint;
@synthesize inputControlToolbar;
@synthesize leftPlaceholderButton;
@synthesize rightPlaceholderButton;
@synthesize rightButton;
@synthesize leftButton;
@synthesize nudgeSetView;
@synthesize nudgeSetViewHeight;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    
    [self registerForKeyboardNotifications];
    [self setupSettings];
    
    [self beginningActions];
    
    [self resetBox];
    
    [self performSelectorOnMainThread:@selector(reloadScreen) withObject:nil waitUntilDone:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self addTapActionIfNeeded];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupSettings
{
    self.shouldReload = NO;
    self.currentlyCellSwiping = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bucketRefreshed:) name:@"bucketRefreshed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removedItemFromBucket:) name:@"removedItemFromBucket" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVCWithLocalKey:) name:@"refreshVCWithLocalKey" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(swipeGestureDidChangeState:) name:@"swipeGestureDidChangeState" object:nil];
    
    page = 0;
    
    [self.textView setFont:[UIFont inputFont]];
    [self.textView setTextColor:[UIColor SHFontDarkGray]];
    
    [self textViewResignedFirstResponder];
    
    CALayer *TopBorder = [CALayer layer];
    TopBorder.frame = CGRectMake(0.0f, 0.0f, self.inputToolbar.bounds.size.width, 1.0f);
    TopBorder.backgroundColor = [UIColor SHLightGray].CGColor;
    [inputToolbar.layer addSublayer:TopBorder];

    CALayer *TopBorder2 = [CALayer layer];
    TopBorder2.frame = CGRectMake(0.0f, 0.0f, self.inputToolbar.bounds.size.width, 1.0f);
    TopBorder2.backgroundColor = [UIColor SHLightGray].CGColor;
    [inputControlToolbar.layer addSublayer:TopBorder2];
    
    [self.inputControlToolbar setBackgroundColor:[[UIColor slightBackgroundColor] colorWithAlphaComponent:0.75f]];
    [self.rightButton setBackgroundColor:[UIColor SHLightBlue]];
    [[self.rightButton titleLabel] setTextColor:[UIColor SHBlue]];
    [[self.rightButton titleLabel] setFont:[UIFont titleMediumFontWithSize:13.0f]];
    
    self.tableView.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, self.tableView.contentInset.bottom+20.0f, self.tableView.contentInset.right)];
    
    if (![self.localKey isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navBucket.png"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemAction:)];
        [self.navigationItem setRightBarButtonItem:item];
    }
    
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.leftButton setImage:[UIImage imageNamed:@"compose-media.png"] forState:UIControlStateNormal];
    [self.leftButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.leftButton setContentMode:UIViewContentModeScaleAspectFit];
    [self.leftButton setTintColor:[UIColor SHGreen]];
    [self.leftButton setTitle:nil forState:UIControlStateNormal];
    
    [self.leftPlaceholderButton setTitle:[NSString stringWithFormat:@" + New Nudge "] forState:UIControlStateNormal];
    [self.leftPlaceholderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.leftPlaceholderButton setBackgroundColor:[UIColor SHGreen]];
    [[self.leftPlaceholderButton titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
    [self.leftPlaceholderButton.layer setCornerRadius:4.0f];
    [self.leftPlaceholderButton setClipsToBounds:YES];
    
    [self.rightPlaceholderButton setTitle:[NSString stringWithFormat:@" + New Noe "] forState:UIControlStateNormal];
    [self.rightPlaceholderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [[self.rightPlaceholderButton titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
    [self.rightPlaceholderButton setBackgroundColor:[UIColor SHBlue]];
    [self.rightPlaceholderButton.layer setCornerRadius:4.0f];
    [self.rightPlaceholderButton setClipsToBounds:YES];
    
    [self.tableView setScrollsToTop:YES];
    [self.textView setScrollsToTop:NO];
}

- (void) addTapActionIfNeeded
{
    if (![[self bucket] isAllThoughtsBucket]) {
        UITapGestureRecognizer *navSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navSingleTap)];
        [navSingleTap setNumberOfTapsRequired:1];
        [[self.navigationController.navigationBar.subviews objectAtIndex:1] setUserInteractionEnabled:YES];
        [[self.navigationController.navigationBar.subviews objectAtIndex:1] addGestureRecognizer:navSingleTap];
    }
}

- (void) beginningActions
{
    [[self bucket] refreshFromServerWithSuccess:^(id responseObject){} failure:^(NSError* error){}];
}

- (void) rightBarButtonItemAction:(UIBarButtonItem*)button
{
    SHEditBucketViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:editBucketIdentifier];
    [vc setLocalKey:self.localKey];
    [self setTitle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}






# pragma mark helpers

- (NSMutableDictionary*) bucket
{
    if ([LXObjectManager objectWithLocalKey:self.localKey]) {
        return [LXObjectManager objectWithLocalKey:self.localKey];
    } else if ([localKey isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        return [@{@"id":@0, @"first_name":@"All Notes", @"object_type":@"all-thoughts"} mutableCopy];
    } else {
        return [@{} mutableCopy];
    }
}





# pragma mark action helpers

- (void) removedItemFromBucket:(NSNotification*)notification
{
    [self reloadScreen];
}

- (void) refreshVCWithLocalKey:(NSNotification*)notification
{
    if ([[[notification userInfo] objectForKey:@"local_key"] isEqualToString:self.localKey]) {
        [self tryToReload];
    }
}







# pragma mark scrolling helpers

- (void) scrollToBottomAnimated
{
    [self scrollToBottom:YES];
}

- (void) scrollToBottom:(BOOL)animated
{
    if ([[[self bucket] itemKeys] count] > 0) {
        if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
        }
    }
}

- (void) scrollToTop:(BOOL)animated
{
    if ([[[self bucket] itemKeys] count] > 0) {
        if ([self.tableView numberOfSections] > 0 && [self.tableView numberOfRowsInSection:0] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(MAX(1, [self.tableView numberOfRowsInSection:0])-1) inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
        }
    }
}

- (BOOL) scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    BOOL should = YES;
    if (should) {
        [self scrollToTop:YES];
    }
    return NO;
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self checkForReload];
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self checkForReload];
}

- (void) tryToReload
{
    if (![self.tableView isDragging] && ![self.tableView isDecelerating] && !self.currentlyCellSwiping) {
        [self reloadScreen];
        self.shouldReload = NO;
    } else {
        self.shouldReload = YES;
    }
}

- (void) checkForReload
{
    if (self.shouldReload) {
        [self reloadScreen];
        self.shouldReload = NO;
    }
}

- (void) swipeGestureDidChangeState:(NSNotification*)notification
{
    if ([[notification userInfo] objectForKey:@"bucketLocalKey"] && [[[notification userInfo] objectForKey:@"bucketLocalKey"] isEqualToString:self.localKey]) {
        self.currentlyCellSwiping = [[[notification userInfo] objectForKey:@"gestureIsActive"] boolValue];
        if (!self.currentlyCellSwiping) {
            [self checkForReload];
        }
    }
}





# pragma mark table view data source and delegate

- (void) bucketRefreshed:(NSNotification*)notification
{
    if ([[notification userInfo] objectForKey:@"bucket"] && [[[[notification userInfo] objectForKey:@"bucket"] localKey] isEqualToString:self.localKey]) {
        //BUCKET MATCHES!
        //[self performSelectorOnMainThread:@selector(reloadIfDifferentCountOfKeys:) withObject:[[notification userInfo] objectForKey:@"oldItemKeys"] waitUntilDone:NO];
        
        //[self reloadScreen];
        [self tryToReload];
        
        if (![[[notification userInfo] objectForKey:@"bucket"] isAllThoughtsBucket]) {
            [self checkSecurity];
        }
    }
}

- (void) reloadIfDifferentCountOfKeys:(NSArray*)oldKeys
{
    //NSLog(@"%lu, %lu", (unsigned long)[[[self bucket] itemKeys] count], (unsigned long)[oldKeys count]);
    if ([[[self bucket] itemKeys] count] == [oldKeys count]) {
    } else {
        [self tryToReload];
    }
}

- (void) addItemsNotSavedToServer
{
    for (NSDictionary*q in [[LXObjectManager defaultManager] queries]) {
        NSDictionary *obj = [q objectForKey:@"object"];
        NSString *method = [q objectForKey:@"method"];
        if (obj) {
            NSMutableDictionary *i = [obj objectForKey:@"item"] ? [[obj objectForKey:@"item"] mutableCopy] : nil;
            if (i && [method isEqualToString:@"POST"] && [i localKey]) {
                if (![[[self bucket] itemKeys] containsObject:[i localKey]]) {
                    [[[self bucket] itemKeys] insertObject:[i localKey] atIndex:0];
                }
            }
        }
    }
}

- (void) reloadScreen
{
    if ([[self bucket] isAllThoughtsBucket]) {
        [self addItemsNotSavedToServer];
    }
    [self.tableView reloadData];
    [self setTitle:[[self bucket] firstName]];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MIN(PAGE_COUNT*(page+1), [[[self bucket] itemKeys] count]);
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([LXObjectManager objectWithLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]]) {
        return [self tableView:tV itemCellForRowAtIndexPath:indexPath];
    } else {
        [[LXObjectManager defaultManager] refreshObjectWithKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]
                                                       success:^(id responseObject){
                                                           //[self.tableView reloadData];
                                                       } failure:nil
         ];
        return [self tableView:tV loadingCellForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell*) tableView:(UITableView *)tV itemCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHItemTableViewCell* cell = (SHItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:itemCellIdentifier];
    [cell configureWithItemLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row] bucketLocalKey:self.localKey];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLoadingTableViewCell* cell = (SHLoadingTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    [cell configureWithResponseObject:[@{@"local_key":[[[self bucket] itemKeys] objectAtIndex:indexPath.row], @"vc":self} mutableCopy]];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tV estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* item = [LXObjectManager objectWithLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]];
    if (item && [item objectForKey:@"estimated_row_height"]) {
        return [[item objectForKey:@"estimated_row_height"] floatValue];
    } else {
        return 83.0f;
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row+1 == [self.tableView numberOfRowsInSection:0] && [self.tableView numberOfRowsInSection:0] < [[[self bucket] itemKeys] count]) {
        page = page+1;
        [self reloadScreen];
        [self.tableView flashScrollIndicators];
    }
    NSMutableDictionary* item = [LXObjectManager objectWithLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]];
    if (item) {
        [item addEstimatedRowHeight:cell.frame.size.height];
    }
    if ([item hasReminder]) {
        [self prePermissionsDelegate:@"notifications" message:[NSString stringWithFormat:@"Enable notifications to get a nudge on the morning of %@%@.", [NSDate timeAgoActualFromDatetime:[item reminderDate]], [item message] && [[item message] length] > 0 ? [NSString stringWithFormat:@" about the thought: \"%@.\"", [item message]] : @""]];
    } else if (![item belongsToCurrentUser]) {
        [self prePermissionsDelegate:@"notifications" message:[NSString stringWithFormat:@"Enable notifications to get a nudge whenever %@ adds a thought to your Hippo.", ([item objectForKey:@"user"] && [[item objectForKey:@"user"] objectForKey:@"name"] && [[[item objectForKey:@"user"] objectForKey:@"name"] length] > 0 ? [[item objectForKey:@"user"] objectForKey:@"name"] : @"a colleague")]];
    }
}

- (void) tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tV deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:itemViewControllerIdentifier];
    [(SHItemViewController*)vc setLocalKey:[[[self bucket] itemKeys] objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:vc animated:YES];
}






# pragma mark toolbar delegate

- (IBAction)rightButtonAction:(id)sender
{
    [self didPressRightButton:sender];
}

- (IBAction)leftButtonAction:(id)sender
{
    [self.textView resignFirstResponder];
    UIActionSheet* as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ? @"Camera" : nil), nil];
    [as setTag:50];
    [as showInView:self.view];
}

- (void) didPressRightButton:(id)sender
{
    [self saveThought];
    
    [self reloadScreen];
    [self scrollToBottom:YES];
    
    [self resetBox];
}

- (void) saveThought
{
    if (![self canSave])
        return;
    
    [self.blankItem setObject:[[[[[self.textView attributedText] string] stringByReplacingOccurrencesOfString:@"\uFFFC" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\uFFFC"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"message"];
    
    if ([self bucket] && [[self bucket] localKey] && ![[[self bucket] localKey] isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        [self.blankItem setObject:[[self bucket] localKey] forKey:@"bucket_local_key"];
        [self.blankItem setObject:@"assigned" forKey:@"status"];
        [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] addItem:self.blankItem atIndex:0];
    }
    [[self bucket] addItem:self.blankItem atIndex:0];
    
    [self.blankItem saveRemote:^(id responseObject) {
        [self reloadScreen];
    }
             failure:^(NSError* error){
             }
     ];
}

- (void) resetBox
{
    [self.textView setAttributedText:[[NSMutableAttributedString alloc] init]];
    [self.textView setText:nil];
    [self textViewDidChange:self.textView];
    
    self.blankItem = [NSMutableDictionary createItemWithMessage:self.textView.text];
}

- (BOOL) canSave
{
    return (self.textView.text && self.textView.text.length > 0) || [self.blankItem hasUnsavedMedia];
}






# pragma mark text view delegate

- (void) textViewDidChange:(UITextView *)tV
{
    [self resizeTextView];
    [self handleButtons];
    [self.textView setFont:[UIFont inputFont]];
}

- (void) resizeTextView
{
    CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.bounds.size.width, MAX_TEXTVIEW_HEIGHT)];
    self.textViewHeightConstraint.constant = MIN(200, MAX(size.height, 56));
    [self.inputToolbar setNeedsLayout];
    [self.inputToolbar layoutIfNeeded];
}

- (void) redrawMessage
{
    NSMutableAttributedString* as = [[NSMutableAttributedString alloc] init];
    if ([self.blankItem hasUnsavedMedia]) {
        for (NSMutableDictionary* medium in [self.blankItem media]) {
            NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
            //textAttachment.image = [[UIImage imageWithContentsOfFile:[medium objectForKey:@"local_file_path"]] resizeImageWithNewSize:[medium sizeWithNewWidth:self.inputToolbar.bounds.size.width]];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[medium objectForKey:@"local_file_name"]];
            textAttachment.image = [UIImage imageWithContentsOfFile:filePath];
            [textAttachment setBounds:CGRectMake(0, 0, self.inputToolbar.bounds.size.width/2.0, [medium heightForWidth:self.inputToolbar.bounds.size.width/2.0])];
            NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
            [as appendAttributedString:attrStringWithImage];
            [as appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
    }
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:[[[[[self.textView attributedText] string] stringByReplacingOccurrencesOfString:@"\uFFFC" withString:@""]stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\uFFFC"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
    [self.textView setAttributedText:as];
    [self textViewDidChange:self.textView];
}

- (BOOL) textView:(UITextView *)tV shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@""]) {
        [self performSelector:@selector(leaveRemainingAttachments) withObject:nil afterDelay:0.05];
    }
    return YES;
}

- (void) leaveRemainingAttachments
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* as = [self.textView.attributedText copy];
        NSMutableArray* remainingImages = [[NSMutableArray alloc] init];
        [as enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, self.textView.attributedText.length) options:0
                    usingBlock:^(id value, NSRange r, BOOL *stop) {
                        NSTextAttachment* attachment = (NSTextAttachment*)value;
                        if (attachment != NULL && attachment.image) {
                            [remainingImages addObject:attachment.image];
                        }
                    }
         ];
        if ([remainingImages count] == [[self.blankItem media] count]) {
            //do nothing
        } else {
            NSMutableArray* tempMedia = [[NSMutableArray alloc] init];
            for (NSMutableDictionary* medium in [self.blankItem media]) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[medium objectForKey:@"local_file_name"]];
                UIImage* comparison = [UIImage imageWithContentsOfFile:filePath];
                if (comparison) {
                    for (UIImage* img in remainingImages) {
                        if ([UIImagePNGRepresentation(img) isEqual:UIImagePNGRepresentation(comparison)]) {
                            [tempMedia addObject:medium];
                        }
                    }
                    //(*stop) = YES; // stop so we only write the first attachment
                }
            }
            [self.blankItem setObject:tempMedia forKey:@"media_cache"];
        }
    });
}





# pragma mark keyboard

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)showKeyboard:(NSNotification*)notification
{
    CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:0.2f animations:^(void){
        self.toolbarBottomConstraint.constant = endFrame.size.height;
    }];
    
    if ([self.textView isFirstResponder]) {
        [self scrollToBottom:YES];
        [self textViewBecameFirstResponder];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)hideKeyboard:(NSNotification*)notification
{
    [UIView animateWithDuration:0.2f animations:^(void){
        self.toolbarBottomConstraint.constant = 0;
    }];
    
    [self textViewResignedFirstResponder];
}

- (void) textViewResignedFirstResponder
{
    if (!self.textView.text || self.textView.text.length == 0) {
        [self.placeholderLabel setHidden:NO];
    }
    self.inputControlToolbarHeightConstraint.constant = 0;
    [self.rightButton setHidden:YES];
    [self handleButtons];
}

- (void) textViewBecameFirstResponder
{
    [self.placeholderLabel setHidden:YES];
    self.inputControlToolbarHeightConstraint.constant = 44.0f;
    [self.rightButton setHidden:NO];
    [self handleButtons];
}

- (void) handleButtons
{
    if ([self canSave]) {
        [self.rightButton setEnabled:YES];
    } else {
        [self.rightButton setEnabled:NO];
    }
}

- (IBAction)leftPlaceholderAction:(id)sender
{
    [self.textView becomeFirstResponder];
    
    [self showNudgeSetView];
    
}

- (IBAction)rightPlaceholderAction:(id)sender
{
    [self.textView becomeFirstResponder];
}

- (void) showNudgeSetView
{
    self.nudgeSetViewHeight.constant = 256;
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
            [imagePicker setMediaTypes:@[(NSString*)kUTTypeImage, (NSString*)kUTTypeMovie]];
            [imagePicker setAllowsEditing:NO];
            [self presentViewController:imagePicker animated:YES completion:^(void){}];
        } else if (buttonIndex == 1) {
            UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [imagePicker setMediaTypes:@[(NSString*)kUTTypeImage, (NSString*)kUTTypeMovie]];
            [imagePicker setAllowsEditing:NO];
            [self presentViewController:imagePicker animated:YES completion:^(void){}];
        }
    }
}





# pragma mark uiimagepicker delegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.textView becomeFirstResponder];
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
        // Media is an image
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        // Create path.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* filename = [NSString stringWithFormat:@"Image-%f.png", [[NSDate date] timeIntervalSince1970]];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
        
        // Save image.
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:YES];
        
        NSMutableDictionary* medium = [NSMutableDictionary create:@"medium"];
        [medium setObject:filename forKey:@"local_file_name"];
        [medium setObject:[self.blankItem localKey] forKey:@"item_local_key"];
        [medium setObject:[NSNumber numberWithFloat:image.size.width] forKey:@"width"];
        [medium setObject:[NSNumber numberWithFloat:image.size.height] forKey:@"height"];
        [medium setObject:@"image" forKey:@"media_type"];
        
        NSMutableArray* tempMedia = [[self.blankItem media] mutableCopy];
        [tempMedia addObject:medium];
        [self.blankItem setObject:tempMedia forKey:@"media_cache"];
        
        [self redrawMessage];
    }
    else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
        
    }
    [picker dismissViewControllerAnimated:NO completion:^(void){}];
}





# pragma mark security check

- (void) checkSecurity
{
    if (![[self bucket] authorizedToSee]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}




# pragma mark navigation bar actions

- (void) navSingleTap
{
    NSLog(@"TAP!!");
}




@end
