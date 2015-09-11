//
//  SHItemViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemViewController.h"
#import "SHSlackThoughtsViewController.h"
#import "SHAssignBucketsViewController.h"
#import "HCReminderViewController.h"

#import "SHItemMessageTableViewCell.h"
#import "SHItemAuthorTableViewCell.h"
#import "SHMediaBoxTableViewCell.h"
#import "SHAttachmentBoxTableViewCell.h"

static NSString *messageCellIdentifier = @"SHItemMessageTableViewCell";
static NSString *authorCellIdentifier = @"SHItemAuthorTableViewCell";
static NSString *mediaBoxCellIdentifier = @"SHMediaBoxTableViewCell";
static NSString *attachmentCellIdentifier = @"SHAttachmentBoxTableViewCell";

@interface SHItemViewController ()

@end

@implementation SHItemViewController

@synthesize localKey;
@synthesize tableView;
@synthesize bottomToolbar;
@synthesize sections;
@synthesize toolbarOptions;
@synthesize trailingSpace;

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
    
    [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 20.0f, self.tableView.contentInset.right)];
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
    [self reloadScreen];
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
    if ([[notification userInfo] objectForKey:@"local_key"] && self.localKey && [[[notification userInfo] objectForKey:@"local_key"] isEqualToString:self.localKey]) {
        [self reloadScreen];
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
    if ([[self item] hasMessage]) {
        [self.sections addObject:@"message"];
    }
    if ([[self item] hasMedia]) {
        [self.sections addObject:@"media"];
    }
    if ([[self item] hasReminder]) {
        [self.sections addObject:@"nudge"];
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"media"]) {
        return [self tableView:tV mediaBoxCellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"nudge"]) {
        return [self tableView:tV attachmentCellForRowAtIndexPath:indexPath attachment:[self item] type:@"nudge"];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        return [self tableView:tV attachmentCellForRowAtIndexPath:indexPath attachment:[[[self item] bucketsArray] objectAtIndex:indexPath.row] type:@"bucket"];
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

- (UITableViewCell*) tableView:(UITableView *)tableView mediaBoxCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHMediaBoxTableViewCell* cell = (SHMediaBoxTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:mediaBoxCellIdentifier];
    [cell configureWithLocalKey:self.localKey medium:[[[self item] media] objectAtIndex:indexPath.row]];
    return cell;
}

- (UITableViewCell*) tableView:(UITableView *)tableView attachmentCellForRowAtIndexPath:(NSIndexPath *)indexPath attachment:(NSMutableDictionary*)attachment type:(NSString*)type
{
    SHAttachmentBoxTableViewCell* cell = (SHAttachmentBoxTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:attachmentCellIdentifier];
    [cell configureWithLocalKey:self.localKey attachment:attachment type:type];
    [cell setDelegate:self];
    return cell;
}



# pragma mark actions

- (void) tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"buckets"]) {
        //PUSH BUCKET!
        UIViewController* vc = [[SHSlackThoughtsViewController alloc] init];
        [(SHSlackThoughtsViewController*)vc setLocalKey:[[[[self item] bucketsArray] objectAtIndex:indexPath.row] localKey]];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"nudge"]) {
        [self presentNudgeScreen];
    }
}

- (void) longPressWithObject:(NSMutableDictionary*)object type:(NSString*)action
{
    NSLog(@"successful %@ call", action);
    if ([action isEqualToString:@"bucket"]) {
        [self presentAssignScreen];
    } else if ([action isEqualToString:@"nudge"]) {
        [self presentNudgeScreen];
    }
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
    [self.toolbarOptions addObject:@"duplicate"];
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
    } else {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:[self optionAtIndex:[sender tag]] message:@"Nice action." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [av show];
    }
}




# pragma mark alert view delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag-100 >= [self.toolbarOptions count]) {
        return;
    }
    if ([[self optionAtIndex:(alertView.tag-100)] isEqualToString:@"delete"]) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [self performDeletion];
        }
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
