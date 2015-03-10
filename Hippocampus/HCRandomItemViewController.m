//
//  HCRandomItemViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/10/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCRandomItemViewController.h"
#import "HCContainerViewController.h"

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
    [self.navigationItem setTitle:@"Random Note"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self askServerForAllItems];
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
    }

    [self.sections addObject:@"all"];
    [self.sections addObject:@"getRandom"];

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
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"getRandom"]) {
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
    } else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"getRandom"]) {
        return [self getRandomCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:2];
    
    [note setText: [self.item objectForKey:@"message"]];
    [timestamp setText:([self.item hasID] ? [NSString stringWithFormat:@"%@%@", ([self.item hasBucketsString] ? [NSString stringWithFormat:@"%@ - ", [self.item bucketsString]] : @""), [NSDate timeAgoInWordsFromDatetime:[self.item createdAt]]] : @"syncing with server")];
    
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [note setNumberOfLines:0];
    
    return cell;
}

- (UITableViewCell*) getRandomCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"randomCell" forIndexPath:indexPath];
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    [note setText:@"Get Random Note"];
    return cell;
}


- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    UIActivityIndicatorView* iav = (UIActivityIndicatorView*) [cell.contentView viewWithTag:10];
    [iav startAnimating];
    return cell;
}

- (UITableViewCell*) explanationCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"explanationCell" forIndexPath:indexPath];
    UILabel* explanation = (UILabel*)[cell.contentView viewWithTag:1];
    [explanation setText:@"You have not created any notes."];
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
        return [self heightForText:[[self.item objectForKey:@"message"] truncated:320] width:280.0f font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return 90.0;
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
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"getRandom"]) {
        [self setRandomItem];
        [self.tableView reloadData];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - Helpers
- (void) askServerForAllItems {
    requestMade = YES;
    [[LXServer shared] getAllItemsWithPage:0
                                   success:^(id responseObject) {
                                       self.allItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
                                       [self setRandomItem];
                                       requestMade = NO;
                                       [self.tableView reloadData];
                                   }
                                   failure:^(NSError* error) {
                                       requestMade = NO;
                                       [self.tableView reloadData];
                                       NSLog(@"ugh");
                                   }
     ];
}

- (void) setRandomItem {
    self.item = [self.allItems rand];
    if ([[self.item objectForKey:@"message"] length] < 2) {
        [self setRandomItem];
    }
}

@end
