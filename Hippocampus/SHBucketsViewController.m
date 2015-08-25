//
//  SHBucketsViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHBucketsViewController.h"
#import "SHBucketTableViewCell.h"
#import "SHSlackThoughtsViewController.h"

static NSString *bucketCellIdentifier = @"SHBucketTableViewCell";

@interface SHBucketsViewController ()

@end

@implementation SHBucketsViewController

@synthesize tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedBucketLocalKeys:) name:@"updatedBucketLocalKeys" object:nil];
    
    [self beginningActions];
}

- (void) setupSettings
{
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:100.0f];
    
    [self.tableView registerNib:[UINib nibWithNibName:bucketCellIdentifier bundle:nil] forCellReuseIdentifier:bucketCellIdentifier];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(64.0f, 0, 0, 0)];
    [self.tableView setBackgroundColor:[UIColor slightBackgroundColor]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadScreen];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadScreen];
}

- (void) beginningActions
{
    [NSMutableDictionary bucketKeysWithSuccess:nil failure:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




# pragma mark notifications

- (void) updatedBucketLocalKeys:(NSNotification*)notification
{
    [self reloadScreen];
}




# pragma mark helpers

- (NSArray*) bucketKeys
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"bucketLocalKeys"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"bucketLocalKeys"] : @[];
}

- (NSMutableDictionary*) bucketAtIndexPath:(NSIndexPath*)indexPath
{
    return [LXObjectManager objectWithLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
}



# pragma mark table view delegate and data source

- (void) reloadScreen
{
    [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self bucketKeys] count];
}

- (UITableViewCell*) tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tV bucketCellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) tableView:(UITableView *)tV bucketCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHBucketTableViewCell* cell = (SHBucketTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:bucketCellIdentifier];
    [cell configureWithBucketLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* bucket = [self bucketAtIndexPath:indexPath];
    return MIN(33.0f,([bucket cachedItemMessage] ? [[bucket cachedItemMessage] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(42.0f)) font:[UIFont titleFontWithSize:14.0f]] : 0)) + ([bucket firstName] ? [[bucket firstName] heightForTextWithWidth:([[UIScreen mainScreen] bounds].size.width-(42.0f)) font:[UIFont titleFontWithSize:16.0f]] : 0) + 39.0f;
}


# pragma mark actions

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* vc = [[SHSlackThoughtsViewController alloc] init];
    [(SHSlackThoughtsViewController*)vc setLocalKey:[[self bucketKeys] objectAtIndex:indexPath.row]];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
