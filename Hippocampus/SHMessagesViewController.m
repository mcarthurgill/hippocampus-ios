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

@synthesize tableView;
@synthesize inputToolbar;
@synthesize textView;
@synthesize toolbarBottomConstraint;
@synthesize textViewHeightConstraint;
@synthesize inputControlToolbarHeightConstraint;
@synthesize inputControlToolbar;
@synthesize rightButton;
@synthesize leftButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:itemCellIdentifier bundle:nil] forCellReuseIdentifier:itemCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:loadingCellIdentifier bundle:nil] forCellReuseIdentifier:loadingCellIdentifier];
    
    [self registerForKeyboardNotifications];
    [self setupSettings];
    
    [self beginningActions];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bucketRefreshed:) name:@"bucketRefreshed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removedItemFromBucket:) name:@"removedItemFromBucket" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVCWithLocalKey:) name:@"refreshVCWithLocalKey" object:nil];
    
    page = 0;
    
    [self.textView setFont:[UIFont inputFont]];
    [self.textView setTextColor:[UIColor SHFontDarkGray]];
    
    [self.placeholderLabel setFont:self.textView.font];
    [self.placeholderLabel setTextColor:[UIColor SHFontLightGray]];
    [self textViewResignedFirstResponder];
    
    CALayer *TopBorder = [CALayer layer];
    TopBorder.frame = CGRectMake(0.0f, 0.0f, self.inputToolbar.bounds.size.width, 1.0f);
    TopBorder.backgroundColor = [UIColor SHLightGray].CGColor;
    [inputToolbar.layer addSublayer:TopBorder];

    CALayer *TopBorder2 = [CALayer layer];
    TopBorder2.frame = CGRectMake(0.0f, 0.0f, self.inputToolbar.bounds.size.width, 1.0f);
    TopBorder2.backgroundColor = [UIColor SHLightGray].CGColor;
    [inputControlToolbar.layer addSublayer:TopBorder2];
    
    [self.inputControlToolbar setBackgroundColor:[UIColor whiteColor]];
    [self.rightButton setBackgroundColor:[UIColor SHLightBlue]];
    [[self.rightButton titleLabel] setTextColor:[UIColor SHBlue]];
    [[self.rightButton titleLabel] setFont:[UIFont titleMediumFontWithSize:13.0f]];
    
    self.tableView.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    if (![self.localKey isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemAction:)];
        [self.navigationItem setRightBarButtonItem:item];
    }
    
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.leftButton setImage:[UIImage imageNamed:@"compose-media.png"] forState:UIControlStateNormal];
    [self.leftButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.leftButton setContentMode:UIViewContentModeScaleAspectFit];
    [self.leftButton setTintColor:[UIColor SHGreen]];
    [self.leftButton setTitle:nil forState:UIControlStateNormal];
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



# pragma mark herlps

- (NSMutableDictionary*) bucket
{
    if ([LXObjectManager objectWithLocalKey:self.localKey]) {
        return [LXObjectManager objectWithLocalKey:self.localKey];
    } else if ([localKey isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        return [@{@"id":@0, @"first_name":@"All Thoughts", @"object_type":@"all-thoughts"} mutableCopy];
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
    if (![self.tableView isDragging] && ![self.tableView isDecelerating]) {
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



# pragma mark table view data source and delegate

- (void) bucketRefreshed:(NSNotification*)notification
{
    if ([[notification userInfo] objectForKey:@"bucket"] && [[[[notification userInfo] objectForKey:@"bucket"] localKey] isEqualToString:self.localKey]) {
        //BUCKET MATCHES!
        //[self performSelectorOnMainThread:@selector(reloadIfDifferentCountOfKeys:) withObject:[[notification userInfo] objectForKey:@"oldItemKeys"] waitUntilDone:NO];
        [self reloadScreen];
    }
}

- (void) reloadIfDifferentCountOfKeys:(NSArray*)oldKeys
{
    NSLog(@"%lu, %lu", (unsigned long)[[[self bucket] itemKeys] count], (unsigned long)[oldKeys count]);
    if ([[[self bucket] itemKeys] count] == [oldKeys count]) {
    } else {
        [self tryToReload];
    }
}

- (void) reloadScreen
{
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
    NSMutableDictionary* item = [NSMutableDictionary createItemWithMessage:self.textView.text];
    if ([self bucket] && [[self bucket] localKey] && ![[[self bucket] localKey] isEqualToString:[NSMutableDictionary allThoughtsLocalKey]]) {
        [item setObject:[[self bucket] localKey] forKey:@"bucket_local_key"];
        [item setObject:@"assigned" forKey:@"status"];
        [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] addItem:item atIndex:0];
    }
    [[self bucket] addItem:item atIndex:0];
    
    [item saveRemote:^(id responseObject) {
        [self reloadScreen];
    }
             failure:^(NSError* error){
             }
     ];
}

- (void) resetBox
{
    [self.textView setText:@""];
    [self textViewDidChange:self.textView];
}

- (BOOL) canSave
{
    return self.textView.text && self.textView.text.length > 0;
}




# pragma mark text view delegate

- (void) textViewDidChange:(UITextView *)tV
{
    [self resizeTextView];
    [self handleButtons];
}

- (void) resizeTextView
{
    CGSize size = [self.textView sizeThatFits:CGSizeMake(self.textView.bounds.size.width, MAX_TEXTVIEW_HEIGHT)];
    self.textViewHeightConstraint.constant = MIN(200, MAX(size.height, 56));
    [self.inputToolbar setNeedsLayout];
    [self.inputToolbar layoutIfNeeded];
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
            [imagePicker setMediaTypes:@[(NSString*)kUTTypeImage]];
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
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
        // Save image.
        [UIImageJPEGRepresentation(image, 0.9) writeToFile:filePath atomically:YES];
        
        NSMutableDictionary* medium = [NSMutableDictionary create:@"medium"];
        [medium setObject:filePath forKey:@"local_file_path"];
        //[medium setObject:[[self item] localKey] forKey:@"item_local_key"];
        [medium setObject:[NSNumber numberWithFloat:image.size.width] forKey:@"width"];
        [medium setObject:[NSNumber numberWithFloat:image.size.height] forKey:@"height"];
        
        //NSMutableArray* tempMedia = [[[self item] media] mutableCopy];
        
        //[tempMedia addObject:medium];
        
        //[[self item] setObject:tempMedia forKey:@"media_cache"];
    }
    else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
        // Media is a video
        //        NSURL *url = info[UIImagePickerControllerMediaURL];
    }
    [picker dismissViewControllerAnimated:NO completion:^(void){}];
}

@end
