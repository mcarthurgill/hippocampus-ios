//
//  SHItemViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemViewController.h"
#import "SHMessagesViewController.h"
#import "SHAssignBucketsViewController.h"
#import "HCReminderViewController.h"
#import "SHEditItemViewController.h"
#import "SHMediaPlayerViewController.h"
#import "SHEmailViewController.h"

#import "SHItemMessageTableViewCell.h"
#import "SHItemAuthorTableViewCell.h"
#import "SHMediaBoxTableViewCell.h"
#import "SHAttachmentBoxTableViewCell.h"
#import "SHAudioAttachmentTableViewCell.h"
#import "SHBucketTableViewCell.h"
#import "SHLinkMetadataTableViewCell.h"

static NSString *messageCellIdentifier = @"SHItemMessageTableViewCell";
static NSString *authorCellIdentifier = @"SHItemAuthorTableViewCell";
static NSString *mediaBoxCellIdentifier = @"SHMediaBoxTableViewCell";
static NSString *attachmentCellIdentifier = @"SHAttachmentBoxTableViewCell";
static NSString *bucketCellIdentifier = @"SHBucketTableViewCell";
static NSString *linkMetadataCellIdentifier = @"SHLinkMetadataTableViewCell";

@interface SHItemViewController ()

@end

@implementation SHItemViewController

@synthesize localKey;
@synthesize mediaInQuestion;
@synthesize tableView;
@synthesize bottomToolbar;
@synthesize sections;
@synthesize toolbarOptions;
@synthesize trailingSpace;
@synthesize outstandingLabel;
@synthesize anAudioStreamer;
@synthesize audioTimer;
@synthesize audioTableViewCell;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSettings];
    [self setupBottomView];
    [self setupToolbar];
    
    [self performSelectorOnMainThread:@selector(reloadScreen) withObject:nil waitUntilDone:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
    [self refreshObject];
}

- (void) setupSettings
{
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:91.0f];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [self.tableView registerNib:[UINib nibWithNibName:authorCellIdentifier bundle:nil] forCellReuseIdentifier:authorCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:messageCellIdentifier bundle:nil] forCellReuseIdentifier:messageCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:mediaBoxCellIdentifier bundle:nil] forCellReuseIdentifier:mediaBoxCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:attachmentCellIdentifier bundle:nil] forCellReuseIdentifier:attachmentCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:bucketCellIdentifier bundle:nil] forCellReuseIdentifier:bucketCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:linkMetadataCellIdentifier bundle:nil] forCellReuseIdentifier:linkMetadataCellIdentifier];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 20.0f, self.tableView.contentInset.right)];
    
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonAction:)];
    [self.navigationItem setRightBarButtonItem:item];
}

- (void) setupBottomView
{
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bottomToolbar.bounds.size.width, 0.5)];
    topView.opaque = YES;
    topView.backgroundColor = [UIColor SHFontLightGray];
    topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.bottomToolbar addSubview:topView];
}

- (void) setTitle
{
    [self setTitle:[NSDate timeAgoInWordsFromDatetime:[[self item] createdAt]]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self addOutstandingLabelIfNecessary];
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) addOutstandingLabelIfNecessary
{
    UIButton* button = [self buttonForOption:@"bucket"];
    if ([[self item] isOutstanding]) {
        if (button) {
            [button setTintColor:[UIColor SHBlue]];
        }
    } else {
        if (button) {
            [button setTintColor:[UIColor SHGreen]];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) refreshObject
{
    [[LXObjectManager defaultManager] refreshObjectWithKey:self.localKey
                                                   success:^(id responseObject){
                                                   }
                                                   failure:^(NSError* error){
                                                   }
     ];
}

- (void) refreshedObject:(NSNotification*)notification
{
    if ([[notification userInfo] objectForKey:@"local_key"] && NULL_TO_NIL([[notification userInfo] objectForKey:@"local_key"]) && self.localKey && [[[notification userInfo] objectForKey:@"local_key"] isEqualToString:self.localKey]) {
        [self reloadScreen];
        [self checkSecurity];
    }
}



# pragma mark helpers

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}






# pragma mark table view delegate

- (void) reloadScreen
{
    [self.tableView reloadData];
    [self setTitle];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    if (![[self item] belongsToCurrentUser]) {
        [self.sections addObject:@"author"];
    }
    //if ([[self item] hasMessage] || [[self item] belongsToCurrentUser]) {
        [self.sections addObject:@"message"];
    //}
    if ([[self item] hasLinks]) {
        [self.sections addObject:@"linkMetadata"];
    }
    if ([[self item] hasMedia]) {
        [self.sections addObject:@"media"];
    }
    if ([[self item] hasReminder]) {
        [self.sections addObject:@"nudge"];
    }
    if ([[self item] hasEmailHTML]) {
        [self.sections addObject:@"email"];
    }
    if ([[self item] hasBuckets]) {
        [self.sections addObject:@"buckets"];
    }
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"author"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"message"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"linkMetadata"]) {
        return [[[self item] links] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"email"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"media"]) {
        return [[[self item] media] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"buckets"]) {
        return [[[self item] bucketsArray] count];
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"nudge"]) {
        return 1;
    }
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"author"]) {
        return [self tableView:tV authorCellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        return [self tableView:tV messsageCellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"linkMetadata"]) {
        return [self tableView:tV linkMetadataCellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"email"]) {
        return [self tableView:tV attachmentCellForRowAtIndexPath:indexPath attachment:[self item] type:@"email"];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return [self tableView:tV mediaBoxCellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"nudge"]) {
        return [self tableView:tV attachmentCellForRowAtIndexPath:indexPath attachment:[self item] type:@"nudge"];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        return [self tableView:tV attachmentCellForRowAtIndexPath:indexPath attachment:[[[self item] bucketsArray] objectAtIndex:indexPath.row] type:@"bucket"];
        //return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tableView authorCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHItemAuthorTableViewCell* cell = (SHItemAuthorTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:authorCellIdentifier];
    [cell configureWithLocalKey:self.localKey];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tableView messsageCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHItemMessageTableViewCell* cell = (SHItemMessageTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:messageCellIdentifier];
    [cell configureWithLocalKey:self.localKey];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tableView linkMetadataCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHLinkMetadataTableViewCell* cell = (SHLinkMetadataTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:linkMetadataCellIdentifier];
    [cell configureWithLinkURLString:[[[self item] links] objectAtIndex:indexPath.row] delegate:self];
    [cell layoutIfNeeded];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tableView mediaBoxCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* medium = [[[self item] media] objectAtIndex:indexPath.row];
    if ([medium isAudio]) {
        SHAttachmentBoxTableViewCell* cell = (SHAttachmentBoxTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:attachmentCellIdentifier];
        [cell configureWithLocalKey:self.localKey attachment:medium type:@"audio"];
        [cell setDelegate:self];
        return cell;
    } else {
        SHMediaBoxTableViewCell* cell = (SHMediaBoxTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:mediaBoxCellIdentifier];
        [cell configureWithLocalKey:self.localKey medium:medium];
        [cell setDelegate:self];
        return cell;
    }
}

- (UITableViewCell*) tableView:(UITableView *)tableView attachmentCellForRowAtIndexPath:(NSIndexPath *)indexPath attachment:(NSMutableDictionary*)attachment type:(NSString*)type
{
    SHAttachmentBoxTableViewCell* cell = (SHAttachmentBoxTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:attachmentCellIdentifier];
    [cell configureWithLocalKey:self.localKey attachment:attachment type:type];
    [cell setDelegate:self];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tV bucketCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHBucketTableViewCell* cell = (SHBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:bucketCellIdentifier];
    [cell configureWithBucketLocalKey:[[[[self item] bucketsArray] objectAtIndex:indexPath.row] localKey]];
    [cell layoutIfNeeded];
    return cell;
}


# pragma mark actions

- (void) tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        //PUSH BUCKET!
        SHMessagesViewController* vc = (SHMessagesViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMessagesViewController"];
        [vc setLocalKey:[[[[self item] bucketsArray] objectAtIndex:indexPath.row] localKey]];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"nudge"]) {
        [self presentNudgeScreen];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"message"]) {
        [self presentEditMessageScreen];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"email"]) {
        [self presentEmailHTMLScreen];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        [self setMediaInQuestion:[[[self item] media] objectAtIndex:indexPath.row]];
        
        if ([self.mediaInQuestion isAudio]) {
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
            NSString *aSongURL = [NSString stringWithFormat:@"%@", [self.mediaInQuestion mediaURL]]; //@"https://res.cloudinary.com/hbztmvh3r/video/upload/v1444709448/RE525c84be9d21589d95e48ba107598624_rclsur.wav"];//,];
             NSLog(@"Song URL : %@", aSongURL);
            AVPlayerItem *aPlayerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:aSongURL]];
            self.anAudioStreamer = [[AVPlayer alloc] initWithPlayerItem:aPlayerItem];
            [self.anAudioStreamer setRate:1.0f];
            [self.anAudioStreamer play];
            
            [self setAudioTableViewCell:[self.tableView cellForRowAtIndexPath:indexPath]];
            //self.audioTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateAudioStream) userInfo:nil repeats:YES];
        } else {
            //SHMediaPlayerViewController* vc = (SHMediaPlayerViewController*)[[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHMediaPlayerViewController"];
            //[vc setMedium:self.mediaInQuestion];
            //[self presentViewController:vc animated:NO completion:^(void){}];
            NYTPhotosViewController *photosViewController = [[NYTPhotosViewController alloc] initWithPhotos:photos];
            [self presentViewController:photosViewController animated:YES completion:nil];
        }
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"linkMetadata"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[[self item] links] objectAtIndex:indexPath.row]]];
    }
}

- (void) updateAudioStream
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSTimeInterval aCurrentTime = CMTimeGetSeconds(self.anAudioStreamer.currentTime);
        NSTimeInterval aDuration = CMTimeGetSeconds(self.anAudioStreamer.currentItem.asset.duration);
        if (aCurrentTime >= aDuration) {
            self.audioTimer = nil;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.audioTableViewCell updateBottomLabel:[NSString stringWithFormat:@"%f/%f", aCurrentTime, aDuration]];
        });
    });
}

- (void) longPressWithObject:(NSMutableDictionary*)object type:(NSString*)action
{
    if ([action isEqualToString:@"bucket"]) {
        [self presentAssignScreen];
    } else if ([action isEqualToString:@"nudge"]) {
        [self presentNudgeScreen];
    } else if ([action isEqualToString:@"media"]) {
        [self setMediaInQuestion:[object mutableCopy]];
        [self presentMediaActionSheet];
    }
}

- (void) rightBarButtonAction:(UIBarButtonItem*)sender
{
    [self presentEditMessageScreen];
}



# pragma mark presentations

- (void) presentAssignScreen
{
    UINavigationController* nc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"navigationSHAssignBucketsViewController"];
    SHAssignBucketsViewController* vc = [[nc viewControllers] firstObject];
    [vc setLocalKey:self.localKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"presentViewController" object:nil userInfo:@{@"viewController":nc}];
}

- (void) presentNudgeScreen
{
    UINavigationController* nc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"navigationHCReminderViewController"];
    HCReminderViewController* vc = [[nc viewControllers] firstObject];
    [vc setLocalKey:self.localKey];
    UIView* backgroundFrame = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:NO];
    [backgroundFrame setAlpha:0.5f];
    [vc.view setBackgroundColor:[UIColor blackColor]];
    [vc.view addSubview:backgroundFrame];
    [vc.view sendSubviewToBack:backgroundFrame];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"presentViewController" object:nil userInfo:@{@"viewController":nc,@"animated":@NO}];
}

- (void) presentEditMessageScreen
{
    SHEditItemViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHEditItemViewController"];
    [vc setLocalKey:self.localKey];
    [self.navigationController pushViewController:vc animated:NO];
}

- (void) presentMediaActionSheet
{
    UIActionSheet* as;
    if ([self.mediaInQuestion belongsToCurrentUser]) {
        as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Image" otherButtonTitles:@"Copy", nil];
        [as setTag:51];
    } else {
        as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Copy Image", nil];
        [as setTag:51];
    }
    if (as) {
        [as showInView:self.bottomToolbar];
    }
}

- (void) presentEmailHTMLScreen
{
    SHEmailViewController* vc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SHEmailViewController"];
    [vc setEmailHTML:[[self item] emailHTML]];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) performDeletion
{
    if ([[LXObjectManager objectWithLocalKey:self.localKey] belongsToCurrentUser]) {
        [[LXObjectManager objectWithLocalKey:self.localKey] destroyItem];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Not yours!" message:@"Since you didn't create this thought, you can't delete it." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [av show];
    }
}



# pragma mark toolbar

- (void) setupToolbar
{
    self.toolbarOptions = [[NSMutableArray alloc] init];
    
    [self.toolbarOptions addObject:@"nudge"];
    [self.toolbarOptions addObject:@"bucket"];
    [self.toolbarOptions addObject:@"media"];
    //[self.toolbarOptions addObject:@"map"];
    [self.toolbarOptions addObject:@"share"];
    [self.toolbarOptions addObject:@"delete"];
    
    NSInteger index = 0;
    for (NSString* option in self.toolbarOptions) {
        UIButton* button = [self buttonForOption:option];
        
        [button setShowsTouchWhenHighlighted:YES];
        [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [button setContentMode:UIViewContentModeScaleAspectFit];
        [button setTintColor:[UIColor SHGreen]];
        [button setTitle:nil forState:UIControlStateNormal];
        
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([option isEqualToString:@"nudge"]) {
            [button setImage:[UIImage imageNamed:@"toolbar_bells.png"] forState:UIControlStateNormal];
        } else if ([option isEqualToString:@"bucket"]) {
            [button setImage:[UIImage imageNamed:@"toolbar_bucket.png"] forState:UIControlStateNormal];
        } else if ([option isEqualToString:@"media"]) {
            [button setImage:[UIImage imageNamed:@"toolbar_media.png"] forState:UIControlStateNormal];
        } else if ([option isEqualToString:@"map"]) {
            [button setImage:[UIImage imageNamed:@"toolbar_location.png"] forState:UIControlStateNormal];
        } else if ([option isEqualToString:@"duplicate"]) {
            [button setImage:[UIImage imageNamed:@"toolbar_duplicate.png"] forState:UIControlStateNormal];
        } else if ([option isEqualToString:@"share"]) {
            [button setImage:[UIImage imageNamed:@"toolbar_share.png"] forState:UIControlStateNormal];
        } else if ([option isEqualToString:@"delete"]) {
            [button setImage:[UIImage imageNamed:@"toolbar_trash.png"] forState:UIControlStateNormal];
        }
        ++index;
    }
    
    [self.bottomToolbar removeConstraint:self.trailingSpace];
    //[self.bottomToolbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[lastButton]-5-|" options:0 metrics:nil views:@{@"lastButton":[self lastButton]}]];
}

- (UIButton*) lastButton
{
    return (UIButton*)[self.bottomToolbar viewWithTag:([self.toolbarOptions count]-1)];
}

- (UIButton*) buttonForOption:(NSString*)option
{
    return (UIButton*)[self.bottomToolbar viewWithTag:([self indexOfOption:option])];
}

- (NSInteger) indexOfOption:(NSString*)option
{
    return [self.toolbarOptions indexOfObject:option];
}

- (NSString*) optionAtIndex:(NSInteger)index
{
    return [self.toolbarOptions objectAtIndex:index];
}

- (void) buttonAction:(UIButton*)sender
{
    if ([[self optionAtIndex:sender.tag] isEqualToString:@"nudge"]) {
        [self presentNudgeScreen];
    } else if ([[self optionAtIndex:sender.tag] isEqualToString:@"bucket"]) {
        [self presentAssignScreen];
    } else if ([[self optionAtIndex:sender.tag] isEqualToString:@"duplicate"]) {
        
        MBProgressHUD* h = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:h];
        h.labelText = @"Copying";
        h.color = [[UIColor SHGreen] colorWithAlphaComponent:0.8f];
        [h show:YES];
        dispatch_queue_t backgroundQueue = dispatch_queue_create("com.busproductions.queuecopy", 0);
        dispatch_async(backgroundQueue, ^{
            [[UIPasteboard generalPasteboard] setItems:@[]];
            if ([[self item] hasMedia] && [[self item] hasMessage]) {
                [[UIPasteboard generalPasteboard] addItems:@[@{(NSString*)kUTTypeUTF8PlainText:[[self item] message]}]];
                for (UIImage* image in [[self item] rawImages]) {
                    [[UIPasteboard generalPasteboard] addItems:@[@{(NSString*)kUTTypePNG:image}]];
                }
            } else if ([[self item] hasMedia]) {
                [[UIPasteboard generalPasteboard] setImages:[[self item] rawImages]];
            } else if ([[self item] hasMessage]) {
                [[UIPasteboard generalPasteboard] setString:[[self item] message]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [h hide:NO];
                [self showCopiedHUD];
            });
        });
    } else if ([[self optionAtIndex:sender.tag] isEqualToString:@"delete"]) {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Delete" message:@"Are you sure you want to delete this thought?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [av setTag:(sender.tag+100)];
        [av show];
    } else if ([[self optionAtIndex:sender.tag] isEqualToString:@"share"]) {
        
        NSMutableArray* activityItems = [[NSMutableArray alloc] init];
        if ([[self item] hasMedia] && [[self item] hasMessage]) {
            [activityItems addObject:[[self item] message]];
            for (UIImage* image in [[self item] rawImages]) {
                [activityItems addObject:image];
            }
        } else if ([[self item] hasMedia]) {
            [activityItems addObjectsFromArray:[[self item] rawImages]];
        } else if ([[self item] hasMessage]) {
            [activityItems addObject:[[self item] message]];
        }
        
        UIActivityViewController* avc = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [self presentViewController:avc animated:YES completion:^(void){}];
        
    } else if ([[self optionAtIndex:sender.tag] isEqualToString:@"media"]) {
        UIActionSheet* as = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ? @"Camera" : nil), nil];
        [as setTag:50];
        [as showInView:self.bottomToolbar];
    } else {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:[self optionAtIndex:[sender tag]] message:@"Coming soon." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [av show];
    }
}




# pragma mark alert view delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView tag] == 91782364) {
        //remove image
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [[self item] removeMediumWithLocalKey:[self.mediaInQuestion localKey]];
            [self reloadScreen];
        }
    }
    if (alertView.tag-100 >= [self.toolbarOptions count]) {
        return;
    }
    if ([[self optionAtIndex:(alertView.tag-100)] isEqualToString:@"delete"]) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [self performDeletion];
        }
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
        } else if (buttonIndex == 1 && buttonIndex != [actionSheet cancelButtonIndex]) {
            UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [imagePicker setMediaTypes:@[(NSString*)kUTTypeImage]];
            [imagePicker setAllowsEditing:NO];
            [self presentViewController:imagePicker animated:YES completion:^(void){}];
        }
    } else if (actionSheet.tag == 51) {
        //image action
        if (buttonIndex == [actionSheet destructiveButtonIndex]) {
            UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Delete Image" message:@"Are you sure you want to delete this image?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [av setTag:(91782364)];
            [av show];
        } else if (buttonIndex != [actionSheet cancelButtonIndex]) {
            //copy image
            
            MBProgressHUD* h = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:h];
            h.labelText = @"Copying";
            h.color = [[UIColor SHGreen] colorWithAlphaComponent:0.8f];
            [h show:YES];
            dispatch_queue_t backgroundQueue = dispatch_queue_create("com.busproductions.queuecopy", 0);
            dispatch_async(backgroundQueue, ^{
                [[UIPasteboard generalPasteboard] setImage:[SGImageCache imageForURL:[self.mediaInQuestion mediaThumbnailURLWithScreenWidth]]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [h hide:NO];
                    [self showCopiedHUD];
                });
            });
            
        } else {
            //NSLog(@"index: %li", (long)buttonIndex);
        }
    }
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString*)kUTTypeImage]) {
        // Media is an image
        UIImage *image = info[UIImagePickerControllerOriginalImage];

        // Create path.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* filename = [NSString stringWithFormat:@"Image-%f.png", [[NSDate date] timeIntervalSince1970]];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
        // Save image.
        [UIImageJPEGRepresentation(image, 0.9) writeToFile:filePath atomically:YES];
        
        NSMutableDictionary* medium = [NSMutableDictionary create:@"medium"];
        [medium setObject:filename forKey:@"local_file_name"];
        [medium setObject:[[self item] localKey] forKey:@"item_local_key"];
        [medium setObject:[NSNumber numberWithFloat:image.size.width] forKey:@"width"];
        [medium setObject:[NSNumber numberWithFloat:image.size.height] forKey:@"height"];
        
        NSMutableArray* tempMedia = [[[self item] media] mutableCopy];
        
        [tempMedia addObject:medium];
        
        [[self item] setObject:tempMedia forKey:@"media_cache"];
        
        [[self item] saveMediaIfNecessary];
        
    }
    else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
        // Media is a video
//        NSURL *url = info[UIImagePickerControllerMediaURL];
    }
    [picker dismissViewControllerAnimated:NO completion:^(void){}];
}



# pragma mark security check

- (void) checkSecurity
{
    if (![[self item] authorizedToSee]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}



# pragma mark hud

- (void) showCopiedHUD
{
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.labelText = @"Copied to Clipboard";
    hud.color = [[UIColor SHGreen] colorWithAlphaComponent:0.8f];
    
    [hud show:NO];
    [hud hide:YES afterDelay:0.5f];
}

@end
