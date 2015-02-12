//
//  HCBucketTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCBucketTableViewController.h"
#import "HCItemTableViewController.h"
#import "HCNewItemTableViewController.h"
#import "HCContainerViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#define PICTURE_HEIGHT 128
#define PICTURE_MARGIN_TOP 8

@interface HCBucketTableViewController ()

@end

@implementation HCBucketTableViewController

@synthesize refreshControl;
@synthesize bucket;
@synthesize sections;
@synthesize allItems;
@synthesize addButton;

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
    
    [self.navigationItem setTitle:[self.bucket objectForKey:@"first_name"]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshChange];
    [self reloadScreen];
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
    
    [self.sections addObject:@"all"];
    
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([[self.sections objectAtIndex:section] isEqualToString:@"all"]) {
        return self.allItems.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        return [self itemCellForTableView:tableView withItem:[self.allItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    }
    return nil;
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
    }
    return 44.0;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        //HCItemTableViewController* itvc = (HCItemTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"itemTableViewController"];
        HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        [itvc setItems:self.allItems];
        [itvc setBucket:self.bucket];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
            NSDictionary* object = [[self allItems] objectAtIndex:indexPath.row];
            [self deleteItem:object];
            [[self allItems] removeObject:object];
            [self reloadScreen];
        }
    }
}


# pragma  mark actions

- (IBAction)addAction:(id)sender
{
//    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//    UINavigationController* itvc = (UINavigationController*)[storyboard instantiateViewControllerWithIdentifier:@"newItemNavigationController"];
//    [(HCNewItemTableViewController*)[[itvc viewControllers] firstObject] setBucketID:[self.bucket objectForKey:@"id"]];
//    [self presentViewController:itvc animated:NO completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"openNewItemScreen" object:nil];
}

- (IBAction)refreshControllerChanged:(id)sender
{
    if (self.refreshControl.isRefreshing) {
        //Make server call here.
        [self refreshChange];
    }
}


- (void) refreshChange
{
    if (requestMade)
        return;
    requestMade = YES;
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", [self.bucket objectForKey:@"id"]] withMethod:@"GET" withParamaters: @{ @"page":@"0"}
                           success:^(id responseObject) {
                               NSLog(@"response: %@", responseObject);
                               self.allItems = [[NSMutableArray alloc] initWithArray:[responseObject objectForKey:@"items"]];
                               requestMade = NO;
                               [self reloadScreen];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               requestMade = NO;
                               [self reloadScreen];
                           }
     ];
}

#pragma mark deletions

- (void) deleteItem:(NSDictionary *)item {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [item objectForKey:@"id"]] withMethod:@"DELETE" withParamaters:nil success:^(id responseObject) {} failure:^(NSError* error) {}];
}
@end
