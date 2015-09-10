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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSettings];
    [self setupBottomView];
    
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
    }
}

- (void) longPressWithObject:(NSMutableDictionary*)object type:(NSString*)action
{
    NSLog(@"successful %@ call", action);
    if ([action isEqualToString:@"bucket"]) {
        [self presentAssignScreen];
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


@end
