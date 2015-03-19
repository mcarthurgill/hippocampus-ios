//
//  HCRandomItemViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/10/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCRandomItemViewController.h"
#import "HCContainerViewController.h"
#import "HCItemTableViewCell.h"
#import "HCIndicatorTableViewCell.h"
#import "HCExplanationTableViewCell.h"

#define IMAGE_FADE_IN_TIME 0.1f

@interface HCRandomItemViewController ()

@end

@implementation HCRandomItemViewController

@synthesize sections;
@synthesize allItems;
@synthesize item;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupProperties];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupProperties {
    requestMade = NO;
    [self.navigationItem setTitle:@"Random Notes"];
    UIBarButtonItem *randButton = [[UIBarButtonItem alloc]
                                                    initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                    target:self
                                                    action:@selector(getRandom)];
    self.navigationItem.rightBarButtonItem = randButton;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.allItems = [[NSMutableArray alloc] init];
    [self askServerForRandomItemsWithLimit:15];
}




# pragma mark - TableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    
    if (requestMade) {
        [self.sections addObject:@"requesting"];
    } else if (self.allItems.count == 0) {
        [self.sections addObject:@"explanation"];
    } else {
        [self.sections addObject:@"all"];
    }
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"]) {
        return 1;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"explanation"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        return [self itemCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"]) {
        return [self indicatorCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return [self explanationCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCItemTableViewCell *cell = (HCItemTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    [cell configureWithItem:item];
    return cell;
}


- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCIndicatorTableViewCell *cell = (HCIndicatorTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    [cell configureAndBeginAnimation];
    return cell;
}

- (UITableViewCell*) explanationCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    HCExplanationTableViewCell *cell = (HCExplanationTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"explanationCell" forIndexPath:indexPath];
    [cell configureWithText:@"You have not created any notes."]; 
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
        int additional = 0;
        if ([self.item hasMediaURLs]) {
            additional = (PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*[[self.item mediaURLs] count];
        }
        return [self heightForText:[self.item truncatedMessage] width:280.0f font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f + additional;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return 120.0f;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
        [itvc setItem:self.item];
        [itvc setItems:self.allItems];
        [itvc setDelegate:self];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - Randomizing Notes
                                   
- (void) askServerForRandomItemsWithLimit:(int)limit {
    requestMade = YES;
    [[LXServer shared] getRandomItemsWithLimit:limit
                success:^(id responseObject){
                    BOOL first = [self firstRequest];
                    [self.allItems addObjectsFromArray:[responseObject objectForKey:@"items"]];
                    [self setRandomItemAndReplace:first];
                    requestMade = NO;
                    [self.tableView reloadData];
                } failure:^(NSError *error){
                    requestMade = NO;
                    [self.tableView reloadData];
                    NSLog(@"error: %@", [error localizedDescription]);
                }];
}

- (BOOL) firstRequest {
    return (self.allItems && self.allItems.count > 0) ? NO : YES;
}

- (void) setRandomItemAndReplace:(BOOL)replace {
    if (self.item) {
        [self.allItems removeObject:self.item];
    }
    if (replace) {
        self.item = [self.allItems rand];
    }
    [self getMoreItemsIfNeeded];
}

- (void) getMoreItemsIfNeeded {
    if (self.allItems && self.allItems.count < 5 && requestMade == NO) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self askServerForRandomItemsWithLimit:15];
        });
    }
}


# pragma mark - Actions

- (void) getRandom {
    [self setRandomItemAndReplace:YES];
    [self.tableView reloadData];
}
                                   
@end
