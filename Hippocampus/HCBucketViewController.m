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
#import "HCBucketDetailsViewController.h"
#import "LXString+NSString.h"
#import "LXAppDelegate.h"
#import "HCItemTableViewCell.h"
#import "UIImage+Helpers.h"
#import <AudioToolbox/AudioToolbox.h>
#import "HCPopUpViewController.h"
#import "HCPermissionViewController.h"

@import AssetsLibrary;

#define IMAGE_FADE_IN_TIME 0.3f
#define PICTURE_HEIGHT_IN_CELL 280
#define PICTURE_MARGIN_TOP_IN_CELL 8

@interface HCBucketViewController ()

@end

@implementation HCBucketViewController

@synthesize bucket;
@synthesize sections;
@synthesize allItems;
@synthesize addButton;
@synthesize tableView;
@synthesize composeTextView;
@synthesize composeView;
@synthesize saveButton;
@synthesize imageAttachments;
@synthesize bottomConstraint;
@synthesize tableviewHeightConstraint;
@synthesize textViewHeightConstraint;
@synthesize textViewBottomVerticalSpaceConstraint;
@synthesize textViewTopVerticalSpaceConstraint;
@synthesize scrollToPosition;
@synthesize page;
@synthesize initializeWithKeyboardUp;
@synthesize delegate;
@synthesize pickerController;
@synthesize metadata;
@synthesize itemForDeletion;
@synthesize congratsView;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshChangeBottom) name:@"appAwake" object:nil];
    
    //remove extra table view lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setupProperties];
    
    [self setNavTitle];
    
    [self setupConstraint];
    [self observeKeyboard];
    [self setLongPressGestureToRemoveItem];
    
    [self refreshChange];
    [self shouldSetKeyboardAsFirstResponder];

    [self setTableScrollToIndex:([self currentArray].count) animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self setTableScrollToIndex:([self currentArray].count) animated:NO];
    });
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setNavTitle];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self.navigationController.visibleViewController isKindOfClass:[HCBucketViewController class]]) {
        if ([self.bucket isAllNotesBucket]) {
            if ([[LXSetup theSetup] visitedThisScreen:self]) {
                NSLog(@"already visited bucket view controller");
            } else {
                NSLog(@"have not visited bucket view controller");
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
                HCPopUpViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"popUpViewController"];
                [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
                [vc setImageForMainImageView:[UIImage imageNamed:@"all-screen.jpg"]];
                [vc setMainLabelText:@"These are all your thoughts. A blue dot means the thought doesn't belong to any collections yet."];
                [self.navigationController presentViewController:vc animated:NO completion:nil];
            }
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self setInitializeWithKeyboardUp:NO];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.composeTextView resignFirstResponder];
}

- (void) setNavTitle
{
    if ([self.bucket isAllNotesBucket]) {
        if ([[[[LXSession thisSession] user] score] integerValue] > 8) {
            [self setTitle:[NSString stringWithFormat:@"All Thoughts (%@)", [[[[LXSession thisSession] user] numberItems] formattedString]]];
        }
    } else {
        [self.navigationItem setTitle:[self.bucket firstName]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupProperties {
    requestMade = NO;
    shouldContinueRequesting = YES;
    
    [composeTextView setScrollEnabled:NO];
    [composeTextView.layer setCornerRadius:4.0f];
    [self setScrollToPosition:@"bottom"];
    [self setPage:0];
    
    if ([self.bucket isAllNotesBucket]) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [self buildCongrats];
    [self getBucketInfo];

    [self cacheImagePickerController];
    self.itemForDeletion = [[NSMutableDictionary alloc] init];
}

-(void) cacheImagePickerController {
    self.pickerController = [[UIImagePickerController alloc]
                                                 init];
    [self.pickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self.pickerController setMediaTypes:[[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil]];
    self.pickerController.delegate = self;
}


#pragma mark - Table view data source

- (void) reloadScreenToIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self reloadScreen];
    [self setTableScrollToIndex:index animated:animated];
}

- (void) reloadScreen
{
    [self.tableView reloadData];
    [self toggleSaveButton];
    [self setNavTitle];
}

- (void) setTableScrollToIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index >= [[self currentArray] count]) {
        --index;
    }
    if ([self currentArray].count > 0 && index < [self currentArray].count) {
        NSIndexPath *ipath = [NSIndexPath indexPathForRow:index inSection: 0];
        if ([self.scrollToPosition isEqualToString:@"bottom"]) {
            [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: animated];
        } else if ([self.scrollToPosition isEqualToString:@"top"]){
            [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionTop animated: animated];
        } else if ([self.scrollToPosition isEqualToString:@"note"]) {
            //do nothing
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
    HCItemTableViewCell *cell = (HCItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    [cell configureWithItem:item];
    return cell;
}

- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    if (!text || [text length] == 0) {
        return 0.0f;
    }
    NSDictionary *attributes = @{NSFontAttributeName: font};
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
        if ([item hasMediaURLs]) {
            additional = (PICTURE_MARGIN_TOP_IN_CELL+PICTURE_HEIGHT_IN_CELL)*[[item mediaURLs] count];
        }
        return [self heightForText:[item truncatedMessage] width:280.0f font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f + additional + 4.0f;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"] && [[[self currentArray] objectAtIndex:indexPath.row] hasID]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
        [itvc setItem:[[self currentArray] objectAtIndex:indexPath.row]];
        [itvc setItems:[self currentArray]];
        [itvc setBucket:self.bucket];
        [itvc setDelegate:self];
        [self setScrollToPosition:@"note"];
        [self.navigationController pushViewController:itvc animated:YES];

    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        [self showHUDWithMessage:@"Syncing Thought"];
        [[LXSession thisSession] attemptNoteSave:[[self currentArray] objectAtIndex:indexPath.row]
                                         success:^(id responseObject) {
                                             [self replacingWithItem:responseObject];
                                             [self.tableView reloadData];
                                             [self hideHUD];
                                         }
                                         failure:^(NSError* error) {
                                             [self hideHUD];
                                         }
         ];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
            [self setItemForDeletion:[[self currentArray] objectAtIndex:indexPath.row]];
            [self alertForDeletion];
        }
    }
}


# pragma  mark actions

- (IBAction)detailsAction:(id)sender {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCBucketDetailsViewController* dvc = (HCBucketDetailsViewController*)[storyboard instantiateViewControllerWithIdentifier:@"detailsViewController"];
    [dvc setBucket:[self.bucket mutableCopy]];
    [dvc setDelegate:self]; 
    [self.navigationController pushViewController:dvc animated:YES];

}

- (IBAction)addAction:(id)sender
{
    if (self.composeTextView.text.length > 0) {
        [self displayCongrats];

        NSMutableDictionary* tempNote = [[NSMutableDictionary alloc] init];
        
        NSString* s = self.imageAttachments && self.imageAttachments.count > 0 && [[self.composeTextView.attributedText.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] < 2 ? @"" : self.composeTextView.attributedText.string;
        
        
        [tempNote setObject:s forKey:@"message"];
        [tempNote setObject:@"once" forKey:@"item_type"];
        [tempNote setObject:[self.bucket objectForKey:@"id"] forKey:@"bucket_id"];
        
        if (![self.bucket isAllNotesBucket]) {
            [tempNote setObject:@"assigned" forKey:@"status"];
        }
        
        [tempNote setObject:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"device_timestamp"];
        [tempNote setObject:[[[LXSession thisSession] user] userID] forKey:@"user_id"];
        
        if (metadata && [metadata hasLocation]) {
            [tempNote setObject:[metadata objectForKey:@"latitude"]  forKey:@"latitude"];
            [tempNote setObject:[metadata objectForKey:@"longitude"]  forKey:@"longitude"];
        } else if ([[LXSession thisSession] hasLocation]) {
            [tempNote setObject:[NSNumber numberWithDouble:[[LXSession currentLocation] coordinate].latitude]  forKey:@"latitude"];
            [tempNote setObject:[NSNumber numberWithDouble:[[LXSession currentLocation] coordinate].longitude]  forKey:@"longitude"];
        }
        
        NSLog(@"%@", self.composeTextView.attributedText.string);

        if (self.imageAttachments && [self.imageAttachments count] > 0) {
            NSMutableArray* mediaURLS = [[NSMutableArray alloc] init];
            for (NSMutableDictionary *d in self.imageAttachments) {
                if ([[d objectForKey:@"type"] isEqualToString:@"image"]) {
                    NSString* path = [LXSession writeImageToDocumentsFolder:[d objectForKey:@"media"]];
                    [mediaURLS addObject:path];
                    [tempNote setObject:@"image" forKey:@"media_type"];
                } else if ([[d objectForKey:@"type"] isEqualToString:@"video"]) {
                    [mediaURLS addObject:[[d objectForKey:@"mediaURL"] absoluteString]]; //had to use absoluteString since you can't store nsurl's in nsuserdefaults. 
                    [tempNote setObject:@"video" forKey:@"media_type"];
                }
            }
            [tempNote setObject:mediaURLS forKey:@"media_urls"];
        }
        [self addItemToTable:[NSDictionary dictionaryWithDictionary:tempNote]];
        [[LXSession thisSession] addUnsavedNote:tempNote toBucket:[NSString stringWithFormat:@"%@",[self.bucket objectForKey:@"id"]]];
        [self setScrollToPosition:@"bottom"];
        [self reloadScreenToIndex:[self currentArray].count animated:YES];
        [self clearTextField:NO];
        [self saveBucket];
        
        [[LXSession thisSession] attemptNoteSave:tempNote
                                         success:^(id responseObject) {
                                             NSLog(@"callback for attempt note save");
                                             [self replacingWithItem:responseObject];
                                             [self reloadScreenToIndex:[self currentArray].count animated:YES];
                               }
                                         failure:^(NSError* error) {
                                   NSLog(@"error: %@", [error localizedDescription]);
                               }
         ];
        [self incrementNoteCreatedInApp];
        
        if ([[UIDevice currentDevice].model isEqualToString:@"iPhone"]) {
            AudioServicesPlaySystemSound (1352); //vibrate
        }
    }
}

- (void) incrementNoteCreatedInApp
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults objectForKey:@"noteCreatedInApp"]) {
            NSInteger createdNotes = [userDefaults integerForKey:@"noteCreatedInApp"];
            [userDefaults setInteger:createdNotes+1 forKey:@"noteCreatedInApp"];
            if ([userDefaults integerForKey:@"noteCreatedInApp"] == 4 && ![LXSession locationPermissionDetermined]) {
                [self.congratsView setAlpha:0.0f];
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
                HCPermissionViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"permissionViewController"];
                [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
                [vc setImageForMainImageView:[UIImage imageNamed:@"permission-screen.jpg"]];
                [vc setMainLabelText:@"Use your phone's location to see your thoughts on a map."];
                [vc setPermissionType:@"location"];
                [vc setDelegate:self];
                [vc setButtonText:@"Grant Location Permission"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController presentViewController:vc animated:NO completion:nil];
                });
            }
        } else {
            [userDefaults setInteger:1 forKey:@"noteCreatedInApp"];
        }
        [userDefaults synchronize];
    });
}

- (void) permissionsDelegate
{
    NSLog(@"permissions delegate!");
}

- (void) replacingWithItem:(NSDictionary*)replacement
{
    BOOL found = NO;
    for (int i = 0; !found && i < self.allItems.count; ++i) {
        if ([[self.allItems objectAtIndex:i] equalsObjectBasedOnTimestamp:replacement]) {
            [self.allItems replaceObjectAtIndex:i withObject:replacement];
            found = YES;
        }
    }
    [self saveBucket];
}

- (void) addItemToTable:(NSDictionary *)item {
    [self.allItems addObject:item];
}

- (void) refreshChange
{
    if (requestMade)
        return;
    requestMade = YES;
    if ([self.bucket isAllNotesBucket]) {
        [self sendRequestForAllItems];
    } else {
        [self sendRequestForBucketShow];
    }
}

- (void) refreshChangeBottom
{
    if (requestMade)
        return;
    requestMade = YES;
    if ([self.bucket isAllNotesBucket]) {
        [self sendRequestForAllItemsWithPage:0];
    } else {
        [self sendRequestForBucketShowWithPage:0];
    }
}

- (void) sendRequestForBucketShow
{
    [self sendRequestForBucketShowWithPage:self.page];
}

- (void) sendRequestForBucketShowWithPage:(int)p
{
    [[LXServer shared] getBucketShowWithPage:p bucketID:[self.bucket ID]
                                     success:^(id responseObject) {
                                         [self refreshWithResponseObject:responseObject];
                                         requestMade = NO;
                                     }
                                     failure:^(NSError* error) {
                                         requestMade = NO;
                                     }
     ];
}

- (void) sendRequestForAllItems
{
    [self sendRequestForAllItemsWithPage:self.page];
}

- (void) sendRequestForAllItemsWithPage:(int)p
{
    [[LXServer shared] getAllItemsWithPage:p
                                   success:^(id responseObject) {
                                       [self refreshWithResponseObject:responseObject];
                                       requestMade = NO;
                                   }
                                   failure:^(NSError* error) {
                                       requestMade = NO;
                                   }
     ];
}

- (void) refreshWithResponseObject:(NSDictionary*)responseObject
{
    BOOL scroll = NO;
    if (!self.allItems || ([responseObject objectForKey:@"page"] && [[responseObject objectForKey:@"page"] integerValue] == 0)) {
        self.allItems = [[NSMutableArray alloc] init];
        scroll = YES;
    }
    
    //NSLog(@"responseObject: %@", responseObject);
    
    NSIndexSet *indexes;
    
    if ([responseObject objectForKey:@"items"]) {
        indexes = [NSIndexSet indexSetWithIndexesInRange:
                               NSMakeRange(0,[[responseObject objectForKey:@"items"] count])];
        if (indexes.count == 0) {
            shouldContinueRequesting = NO;
        }
        if ([[responseObject objectForKey:@"page"] integerValue] == 0) {
            NSMutableArray* pending = [[LXSession thisSession] unsavedNotesForBucket:[NSString stringWithFormat:@"%@", [self.bucket objectForKey:@"id"]]];
            self.allItems = [[NSMutableArray alloc] initWithArray:(pending ? pending : @[])];
            [self.allItems insertObjects:[responseObject objectForKey:@"items"] atIndexes:indexes];
        } else {
            [self.allItems insertObjects:[responseObject objectForKey:@"items"] atIndexes:indexes];
        }
        [self reloadScreen]; 
    }
    
    if ([responseObject objectForKey:@"outstanding_items"] && [[responseObject objectForKey:@"page"] integerValue] == 0) {
        [self.allItems addObjectsFromArray:[responseObject objectForKey:@"outstanding_items"]];
        if ([[responseObject objectForKey:@"outstanding_items"] count] > 0) {
            [self reloadScreenToIndex:[self currentArray].count animated:NO];
        }
    } else if ([[responseObject objectForKey:@"items"] count] > 0) { //} else if (scroll && [[responseObject objectForKey:@"items"] count] > 0) {
        [self reloadScreenToIndex:indexes.count animated:NO];
    }
    
    if ([responseObject objectForKey:@"bottom_items"] && [responseObject objectForKey:@"page"]) {
        indexes = [NSIndexSet indexSetWithIndexesInRange:
                               NSMakeRange(0,[[responseObject objectForKey:@"bottom_items"] count])];
        if (indexes.count == 0) {
            shouldContinueRequesting = NO;
        }
        [self.allItems insertObjects:[responseObject objectForKey:@"bottom_items"] atIndexes:indexes];
        [self setScrollToPosition:@"top"];
        [self reloadScreenToIndex:indexes.count animated:NO];
    }
    
    if ([[responseObject objectForKey:@"items"] count] > 0 || [[responseObject objectForKey:@"bottom_items"] count] > 0) {
        [self setPage:([[responseObject objectForKey:@"page"] integerValue] + 1)];
        NSLog(@"page: %i", self.page);
    }
}

- (void) shouldRequestMoreItems
{
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
    NSIndexPath *firstRow = [visibleRows firstObject];
    if (firstRow.row == 0 && requestMade == NO && shouldContinueRequesting == YES) {
        [self refreshChange];
    }
}

- (void) getBucketInfo
{
    if (![self.bucket isAllNotesBucket]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[LXServer shared] getBucketInfoWithPage:self.page bucketID:[self.bucket ID] success:^(id responseObject) {
                [self refreshWithResponseObject:responseObject];
                [self setBucket:[responseObject objectForKey:@"bucket"]];
            }failure:^(NSError *error) {
                NSLog(@"damn!");
            }];
        });
    }
}


- (void) deleteItemFromServerAndTable:(NSDictionary *)item
{
    if ([item belongsToCurrentUser]) {
        [self deleteItem:item];
        [[self allItems] removeObject:item];
        [self reloadScreen];
    }
}

- (void) deleteItem:(NSDictionary *)item
{
    if ([item belongsToCurrentUser]) {
        [item deleteItemWithSuccess:nil failure:nil];
    }
}

- (void) updateItemsArrayWithOriginal:(NSMutableDictionary*)original new:(NSMutableDictionary*)n
{
    int index = (int)[self.allItems indexOfObject:original];
    if (index && index < self.allItems.count) {
        [self.allItems replaceObjectAtIndex:index withObject:n];
    }
    [self.tableView reloadData];
}

- (void) scrollToNote:(NSMutableDictionary*)original
{
    [self setScrollToPosition:@"note"];
    int index = (int)[[self currentArray] indexOfObject:original];
    if (index && index < [self currentArray].count) {
        [self setTableScrollToIndex:index animated:NO];
    }
}



# pragma mark helpers

- (NSMutableArray*) currentArray
{
    if (!self.allItems) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:[self currentBucketID]]) {
            self.allItems = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:[self currentBucketID]]];
            //return [[NSUserDefaults standardUserDefaults] objectForKey:[self currentBucketID]];
        }
    }
    return self.allItems;
}

- (BOOL) canSaveNote
{
    return (self.composeTextView.text && self.composeTextView.text.length > 0 && [self.composeTextView.textColor isEqual:[UIColor blackColor]]) || [self hasUploadedImageFromLibrary];
}

- (BOOL) hasUploadedImageFromLibrary {
    __block BOOL attached = NO;
    [self.composeTextView.attributedText enumerateAttribute:NSAttachmentAttributeName
                                 inRange:NSMakeRange(0, self.composeTextView.attributedText.length)
                                 options:0
                              usingBlock:^(id value, NSRange range, BOOL *stop)
          {
              NSTextAttachment* attachment = (NSTextAttachment*)value;
              if (attachment) {
                  attached = YES;
              } else {
                  [self.imageAttachments removeAllObjects];
              }
              (*stop) = YES; // stop after the first attachment
          }];
    return attached;
}

- (void) saveBucket
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self.allItems count] > 0) {
            //NSLog(@"array: %@", self.allItems);
            [[NSUserDefaults standardUserDefaults] setObject:[self itemsToSave] forKey:[self currentBucketID]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    });
}

- (NSString*) currentBucketID
{
    return [NSString stringWithFormat:@"%@", [self.bucket ID]];
}

- (NSMutableArray*) itemsToSave
{
    NSMutableArray* temp = [[NSMutableArray alloc] init];
    for (NSDictionary* t in self.allItems) {
        [temp addObject:[t cleanDictionary]];
    }
    return temp;
}




# pragma mark Textview

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self setScrollToPosition:@"bottom"];
    [self setTableScrollToIndex:[[self currentArray] count] animated:YES];
    
    if ([textView.text isEqualToString:@"Add Thought"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self updateConstraintsForTextView:textView];
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Add Thought";
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

- (void) textViewDidChange:(UITextView *)textView
{
    [self updateConstraintsForTextView:textView];
    [self toggleSaveButton];
    if (textView.text.length == 0) {
        [textView setText:@""];
        [textView setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
    } else {
        textView.textColor = [UIColor blackColor];
    }
}

- (void) updateConstraintsForTextView:(UITextView *)textView {
    float difference = textView.intrinsicContentSize.height - self.textViewHeightConstraint.constant;
    if (difference != 0.0) {
        self.textViewHeightConstraint.constant = textView.intrinsicContentSize.height;
        self.tableviewHeightConstraint.constant = self.tableviewHeightConstraint.constant - difference - self.textViewTopVerticalSpaceConstraint.constant - self.textViewBottomVerticalSpaceConstraint.constant;
        [UIView animateWithDuration:0.0 animations:^{
            [self.view layoutIfNeeded];
        }];
        [self setTableScrollToIndex:[[self currentArray] count] animated:YES];
    }
}


- (void) clearTextField:(BOOL)dismissKeyboard
{
    self.textViewHeightConstraint.constant = self.saveButton.frame.size.height - self.textViewTopVerticalSpaceConstraint.constant - self.textViewBottomVerticalSpaceConstraint.constant;
    
    if ([self.composeTextView attributedText] && [[self.composeTextView attributedText] length] > 0) {
        [self.composeTextView setAttributedText:[[NSAttributedString alloc] initWithString:@""]];
        [self.composeTextView setText:@""];
        [self.composeTextView setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
    }
    
    if (self.imageAttachments && [self.imageAttachments count] > 0) {
        self.imageAttachments = [[NSMutableArray alloc] init];
    }
    
    if (!dismissKeyboard && [self.composeTextView isFirstResponder]) {
        self.composeTextView.text = @"";
        self.composeTextView.textColor = [UIColor blackColor];
    } else {
        self.composeTextView.text = @"Add Thought";
        self.composeTextView.textColor = [UIColor lightGrayColor];
        [self.composeTextView resignFirstResponder];
    }
}


- (void) shouldSetKeyboardAsFirstResponder {
    if (self.initializeWithKeyboardUp) {
        [self.composeTextView becomeFirstResponder];
    }
}

# pragma mark Keyboard Notifications

- (void) observeKeyboard
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}


- (void) keyboardWillShow:(NSNotification *)sender
{
    if (self.isViewLoaded && self.view.window) {
        [self setScrollToPosition:@"bottom"];
        [self setTableScrollToIndex:[self currentArray].count animated:YES];
        
        NSDictionary *info = [sender userInfo];
        NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        CGRect frame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        self.bottomConstraint.constant = frame.origin.y - CGRectGetHeight(self.view.frame);
        
        self.tableviewHeightConstraint.constant = self.tableviewHeightConstraint.constant - frame.size.height;
        
        [UIView animateWithDuration:animationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void) keyboardWillHide:(NSNotification *)sender
{
    if (self.isViewLoaded && self.view.window) {
        NSDictionary *info = [sender userInfo];
        NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        self.bottomConstraint.constant = 0;

        self.tableviewHeightConstraint.constant = self.view.frame.size.height - self.saveButton.frame.size.height;

        [UIView animateWithDuration:animationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void) keyboardWillChangeFrame:(NSNotification *)sender
{
    NSLog(@"changed frame");
}



# pragma mark Constraints

-(void) setupConstraint
{
    self.composeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.composeView];
    
    NSDictionary *views = @{@"view": self.composeView,
                            @"top": self.topLayoutGuide };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[top][view]" options:0 metrics:nil views:views]];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.composeView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.bottomConstraint];
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


# pragma mark upload images

- (IBAction)uploadImage:(id)sender {
    [self showHUDWithMessage:@"Loading pictures"];
    [self presentViewController:self.pickerController animated:YES completion:nil];
    [self hideHUD];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self textViewDidBeginEditing:self.composeTextView];
    [self.saveButton setEnabled:YES];
    
    metadata = [[NSMutableDictionary alloc] init];
    
    NSURL* tempURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (tempURL) {
        ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *myAsset) {
            CLLocation* l = [myAsset valueForProperty:ALAssetPropertyLocation];
            if (l && [l coordinate].latitude && [l coordinate].longitude) {
                NSLog(@"location: %@", l);
                NSLog(@"coordinates: %f, %f", [l coordinate].latitude, [l coordinate].longitude);
                [metadata setObject:[NSNumber numberWithDouble:[l coordinate].latitude] forKey:@"latitude"];
                [metadata setObject:[NSNumber numberWithDouble:[l coordinate].longitude] forKey:@"longitude"];
            } else {
                metadata = [[NSMutableDictionary alloc] init];
            }
        };
        ALAssetsLibrary *assetsLib = [[ALAssetsLibrary alloc] init];
        [assetsLib assetForURL:tempURL resultBlock:resultBlock failureBlock:nil];
    }
    
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeImage]) {
        [self updateComposeViewWithImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    } else if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeMovie]) {
        [self updateComposeViewWithVideo:[info objectForKey:UIImagePickerControllerMediaURL]];
    }
    
    [self dismissViewControllerAnimated:YES completion:^(void){
        [self.composeTextView becomeFirstResponder];
    }];
}

- (void) updateComposeViewWithImage:(UIImage*)image
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\r%@", self.composeTextView.attributedText.string]];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    
    self.imageAttachments = [[NSMutableArray alloc] init];
    NSMutableDictionary *imgDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:image, @"media", @"image", @"type", nil];
    [self.imageAttachments addObject:imgDict];
    
    [attributedString setAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f] forKey:NSFontAttributeName] range:NSMakeRange(0, attributedString.length)];
    
    textAttachment.image = [image scaledToSize:200.0f];
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
    [attributedString replaceCharactersInRange:NSMakeRange(0, 0) withAttributedString:attrStringWithImage];
    
    self.composeTextView.attributedText = attributedString;
    self.textViewHeightConstraint.constant = self.composeTextView.intrinsicContentSize.height;

    [self dismissViewControllerAnimated:YES completion:^(void){
        [self.composeTextView becomeFirstResponder];
    }];
}

- (void) updateComposeViewWithVideo:(NSURL*)mediaURL
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\r%@", self.composeTextView.attributedText.string]];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    
    self.imageAttachments = [[NSMutableArray alloc] init];
    UIImage *image = [self grabThumbnail:mediaURL];
    NSMutableDictionary *vidDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:image, @"media", @"video", @"type", mediaURL, @"mediaURL", nil];
    
    [self.imageAttachments addObject:vidDict];
    
    [attributedString setAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f] forKey:NSFontAttributeName] range:NSMakeRange(0, attributedString.length)];
    
    textAttachment.image = [image scaledToSize:200.0f];
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
    [attributedString replaceCharactersInRange:NSMakeRange(0, 0) withAttributedString:attrStringWithImage];
    
    self.composeTextView.attributedText = attributedString;
    self.textViewHeightConstraint.constant = self.composeTextView.intrinsicContentSize.height;
    
    [self dismissViewControllerAnimated:YES completion:^(void){
        [self.composeTextView becomeFirstResponder];
    }];
}

- (UIImage*)grabThumbnail:(NSURL*)vidURL
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:vidURL options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 60);
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    return [[UIImage alloc] initWithCGImage:imgRef];
}

- (UIImageOrientation) properOrientationForImage:(UIImage *)image
{
    if (image.imageOrientation == 1) {
        return UIImageOrientationDown;
    } else if (image.imageOrientation == 2) {
        return UIImageOrientationLeft;
    } else if (image.imageOrientation == 3) {
        return UIImageOrientationRight;
    }
    return UIImageOrientationUp;
}





# pragma mark - HCUpdateBucketDelegate

-(void)updateBucket:(NSMutableDictionary *)updatedBucket
{
    self.bucket = updatedBucket;
    [self.delegate sendRequestForUpdatedBucket];
}





# pragma  mark - AlertView Delegate

- (void) alertForDeletion {
    NSString *title = @"Sorry";
    NSString *message = @"You cannot delete a thought you did not add!";
    NSString *buttonTitle = @"Okay";
    NSString *cancelTitle = nil;
    
    if (self.itemForDeletion && [self.itemForDeletion belongsToCurrentUser]) {
        title = @"Are you sure?";
        message = @"Do you want to delete this thought?";
        buttonTitle = @"Delete";
        cancelTitle = @"Cancel";
    }
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:cancelTitle
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:buttonTitle];
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if(self.itemForDeletion) {
            [self deleteItemFromServerAndTable:self.itemForDeletion];
        }
    }
}


# pragma mark - Gesture Recognizers

- (void) setLongPressGestureToRemoveItem {
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.7; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    NSLog(@"handle long press");
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"] && [[self currentArray] objectAtIndex:indexPath.row]) {
            [self setItemForDeletion:[[self currentArray] objectAtIndex:indexPath.row]];
            [self alertForDeletion];
        }
    }
}



# pragma mark - Congratulations Notifications

- (void) buildCongrats {
    self.congratsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.navigationController.navigationBar.frame.size.height+[UIApplication sharedApplication].statusBarFrame.size.height)];
    
    UILabel *congratsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, self.congratsView.frame.size.width, self.navigationController.navigationBar.frame.size.height)];
    
    [congratsLabel setText: [NSString randomCongratulations]];
    [congratsLabel setTag:1];
    [congratsLabel setTextAlignment:NSTextAlignmentCenter];
    congratsLabel.layer.cornerRadius = 8.0f;
    [congratsLabel setClipsToBounds:YES];
    [congratsLabel setBackgroundColor:[UIColor clearColor]];
    [congratsLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f]];
    
    [self.congratsView addSubview:congratsLabel];
    [self.congratsView setBackgroundColor:[UIColor whiteColor]];
    [self.congratsView setAlpha:0.0];
    
    LXAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.window addSubview:self.congratsView];
}

- (void) displayCongrats {
    UILabel *lbl = (UILabel *)[self.congratsView viewWithTag:1];
    
    
    [lbl setText:[NSString randomCongratulations]];
    [UIView animateWithDuration:0.5 animations:^{
        [self.congratsView setAlpha:1.0];
    }];
    
    [self performSelector:@selector(hideCongrats) withObject:nil afterDelay:2.0];
}

- (void) hideCongrats {
    [UIView animateWithDuration:0.5 animations:^{
        [self.congratsView setAlpha:0.0];
    }];
}

@end
