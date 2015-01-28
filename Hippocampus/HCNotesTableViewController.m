//
//  HCNotesTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCNotesTableViewController.h"
#import "HCItemTableViewController.h"
#import <QuartzCore/QuartzCore.h>

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#define PICTURE_HEIGHT 128
#define PICTURE_MARGIN_TOP 8

@interface HCNotesTableViewController ()

@end

@implementation HCNotesTableViewController

@synthesize refreshControl;
@synthesize searchBar;
@synthesize sections;
@synthesize allItems;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    requestMade = NO;
    [self refreshChange:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadItemsNotification) name:@"reloadItems" object:nil];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void) reloadScreen
{
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    
    if (self.outstandingItems.count > 0) {
        [self.sections addObject:@"outstanding"];
    }
    
    [self.sections addObject:@"all"];
    
    if (requestMade) {
        [self.sections addObject:@"requesting"];
    }
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return self.allItems.count;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"outstanding"]) {
        return self.outstandingItems.count;
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"requesting"]) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        return [self itemCellForTableView:tableView withItem:[self.allItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"outstanding"]) {
        return [self itemCellForTableView:tableView withItem:[self.outstandingItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"]) {
        return [self indicatorCellForTableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) indicatorCellForTableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"indicatorCell" forIndexPath:indexPath];
    UIActivityIndicatorView* iav = (UIActivityIndicatorView*) [cell.contentView viewWithTag:10];
    [iav startAnimating];
    return cell;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    float width = note.frame.size.width;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[[item objectForKey:@"message"] truncated:320] width:width font:note.font])];
    [note setText:[[item objectForKey:@"message"] truncated:320]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    //NSLog(@"message: %@, height: %f", [item objectForKey:@"message"], note.frame.size.height);
    
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
        NSDictionary* item = [self.allItems objectAtIndex:indexPath.row];
        int additional = 0;
        if ([item objectForKey:@"media_urls"]) {
            additional = (PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*[[item objectForKey:@"media_urls"] count];
        }
        return [self heightForText:[[item objectForKey:@"message"] truncated:320] width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f + 14.0f + additional;
    } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"outstanding"]) {
        NSDictionary* item = [self.outstandingItems objectAtIndex:indexPath.row];
        int additional = 0;
        if ([item objectForKey:@"media_urls"]) {
            additional = (PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*[[item objectForKey:@"media_urls"] count];
        }
        return [self heightForText:[[item objectForKey:@"message"] truncated:320] width:280.0f font:[UIFont systemFontOfSize:17.0]] + 22.0f + 12.0f + 14.0f + additional;
    }
    return 44.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"outstanding"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        [itvc setItem:[self.outstandingItems objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return @"All Notes";
    } else if ([[self.sections objectAtIndex:section] isEqualToString:@"outstanding"]) {
        return @"Notes Not In Stacks";
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
            NSDictionary* object = [[self allItems] objectAtIndex:indexPath.row];
            [self deleteItem:object];
            [[self allItems] removeObjectAtIndex:indexPath.row];
            [self reloadScreen];
        } else if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"outstanding"]) {
            NSDictionary* object = [[self outstandingItems] objectAtIndex:indexPath.row];
            [self deleteItem:object];
            [[self outstandingItems] removeObjectAtIndex:indexPath.row];
            [self reloadScreen];
        }
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    // NSLog(@"offset: %f", offset.y);
    // NSLog(@"content.height: %f", size.height);
    // NSLog(@"bounds.height: %f", bounds.size.height);
    // NSLog(@"inset.top: %f", inset.top);
    // NSLog(@"inset.bottom: %f", inset.bottom);
    // NSLog(@"pos: %f of %f", y, h);
    
    float reload_distance = 10;
    if(y > h + reload_distance) {
        NSLog(@"load more rows");
        [self refreshChange:self.allItems.count/64];
    }
}


# pragma mark refresh controller

- (void) reloadItemsNotification
{
    [self refreshChange:0];
}

- (void) refreshChange:(int)page
{
    if (requestMade)
        return;
    requestMade = YES;
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: @{ @"page":[NSNumber numberWithInt:page]}
                           success:^(id responseObject) {
                               //NSLog(@"response: %@", responseObject);
                               if ([responseObject objectForKey:@"outstanding_items"]) {
                                   self.outstandingItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"outstanding_items"]];
                               }
                               if ([responseObject objectForKey:@"items"]) {
                                   self.allItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
                               }
                               if ([responseObject objectForKey:@"bottom_items"] && [responseObject objectForKey:@"page"]) {
                                   //add to bottom of all Items & refresh!
                                   if (self.allItems.count%64==0 && self.allItems.count <= 64*[[responseObject objectForKey:@"page"] integerValue]) {
                                       [self.allItems addObjectsFromArray:[responseObject objectForKey:@"bottom_items"]];
                                   }
                               }
                               requestMade = NO;
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               [self reloadScreen];
                           }
     ];
    [self reloadScreen];
}

- (IBAction)refreshControllerChanged:(id)sender
{
    if (self.refreshControl.isRefreshing) {
        //Make server call here.
        [self refreshChange:0];
    }
}


# pragma mark toolbar actions

- (IBAction)addAction:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"openNewItemScreen" object:nil];
}


# pragma mark search bar delegate

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)sB
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UINavigationController* nc = [storyboard instantiateViewControllerWithIdentifier:@"searchNavigationController"];
    [self presentViewController:nc animated:NO completion:nil];
    return NO;
}

#pragma mark deletions

- (void) deleteItem:(NSDictionary *)item {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [item objectForKey:@"id"]] withMethod:@"DELETE" withParamaters:nil success:^(id responseObject) {} failure:^(NSError* error) {}];
}

@end
