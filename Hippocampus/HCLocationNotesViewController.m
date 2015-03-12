//
//  HCLocationNotesViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCLocationNotesViewController.h"
#import "HCContainerViewController.h"
@import MapKit;

#define IMAGE_FADE_IN_TIME 0.1f

@interface HCLocationNotesViewController ()

@end

@implementation HCLocationNotesViewController

@synthesize sections;
@synthesize allItems;
@synthesize mapViewHeightConstraint;
@synthesize tableViewHeightConstraint;

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
    [self.navigationItem setTitle:@"Nearby Notes"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.allItems = [[NSMutableArray alloc] init];
    [self getLocationBasedItems];
}



# pragma mark - Create and Setup MapView

- (void) setupMapView {
    
    MKMapView* mv = (MKMapView*)[self.view viewWithTag:19];
    
    [self setupMapAndTableConstraints];
    [self addAnnotationsToMapView:mv];
    [self makeMapView:mv visibleWithZoom:[self setMapZoom]];
}

- (void) addAnnotationsToMapView:(MKMapView*)mv {
    for (NSDictionary*item in self.allItems) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        [annotation setCoordinate:[item location].coordinate];
        [annotation setTitle:[[item message] truncated:20]];
        [mv addAnnotation:annotation];
    }
}

- (void) setupMapAndTableConstraints {
    mapViewHeightConstraint.constant = self.view.frame.size.height*0.5;
    tableViewHeightConstraint.constant = self.view.frame.size.height - mapViewHeightConstraint.constant + self.navigationController.navigationBar.frame.size.height;
    
    [UIView animateWithDuration:0.0 animations:^{
        [self.view layoutIfNeeded];
    }];
    
}

- (MKMapRect) setMapZoom {
    MKMapRect zoomRect = MKMapRectNull;
    MKMapPoint annotationPoint = MKMapPointForCoordinate([[LXSession currentLocation] coordinate]);
    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    return zoomRect;
}

- (void) makeMapView:(MKMapView *)mv visibleWithZoom:(MKMapRect)zoomRect {
    [mv setVisibleMapRect:zoomRect animated:NO];
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
        return self.allItems.count;
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
        return [self itemCellForTableView:self.tableView withItem:[self.allItems objectAtIndex:indexPath.row] cellForRowAtIndexPath:indexPath];
    } else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"requesting"]) {
        return [self indicatorCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    } else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"explanation"]) {
        return [self explanationCellForTableView:self.tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (UITableViewCell*) itemCellForTableView:(UITableView*)tableView withItem:(NSDictionary*)item cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"itemCell" forIndexPath:indexPath];
    
    UILabel* note = (UILabel*)[cell.contentView viewWithTag:1];
    UIFont* font = note.font;
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    
    float width = self.view.frame.size.width - 10 - 25;
    [note removeFromSuperview];
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[item truncatedMessage] width:width font:font]+4.0f)];
    [note setFont:font];
    [note setText:[item truncatedMessage]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.contentView addSubview:note];
    
    //put distance instead of timestamp
    UILabel* timestamp = (UILabel*)[cell.contentView viewWithTag:2];
    [timestamp setText:([item hasID] ? [NSString stringWithFormat:@"%@%@", ([item hasBucketsString] ? [NSString stringWithFormat:@"%@ - ", [item bucketsString]] : @""), [NSDate timeAgoInWordsFromDatetime:[item createdAt]]] : @"syncing with server")];
    
    int i = 0;
    while ([cell.contentView viewWithTag:(200+i)]) {
        [[cell.contentView viewWithTag:(200+i)] removeFromSuperview];
        ++i;
    }
    
    if ([item croppedMediaURLs]) {
        int j = 0;
        for (NSString* url in [item croppedMediaURLs]) {
            UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, note.frame.origin.y+note.frame.size.height+PICTURE_MARGIN_TOP+(PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*j, cell.contentView.frame.size.width-40.0f, PICTURE_HEIGHT)];
            [iv setTag:(200+j)];
            [iv setContentMode:UIViewContentModeScaleAspectFill];
            [iv setClipsToBounds:YES];
            [iv.layer setCornerRadius:8.0f];
            if ([item hasID]) {
                [SGImageCache getImageForURL:url thenDo:^(UIImage* image) {
                    if (image) {
                        [iv setAlpha:0.0f];
                        iv.image = image;
                        [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                            [iv setAlpha:1.0f];
                        }];
                    }
                }];
            } else {
                [iv setAlpha:0.0f];
                iv.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:url]];
                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                    [iv setAlpha:1.0f];
                }];
                
            }
            [cell.contentView addSubview:iv];
            ++j;
        }
    }
    
    
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
    if ([[LXSession thisSession] hasLocation]) {
        [explanation setText:@"You haven't created any notes near your current location."];
    } else {
        [explanation setText:@"You need to give us location permission for this feature. Settings > Privacy > Location Services > Hippocampus"];
    }
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
        NSDictionary *item = [self.allItems objectAtIndex:indexPath.row];
        int additional = 0;
        if ([item hasMediaURLs]) {
            additional = (PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*[[item mediaURLs] count];
        }
        return [self heightForText:[item truncatedMessage] width:280.0f font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f + additional;
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
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        [itvc setItems:self.allItems];
        [itvc setDelegate:self];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


# pragma mark - Location Based Notes

- (void) getLocationBasedItems {
    requestMade = YES;
    CLLocationCoordinate2D loc = [LXSession currentLocation].coordinate;
    [[LXServer shared] requestPath:@"/items/near_location.json" withMethod:@"GET" withParamaters: @{ @"user_id": [[HCUser loggedInUser] userID], @"latitude": [NSString stringWithFormat:@"%f", loc.latitude], @"longitude": [NSString stringWithFormat:@"%f", loc.longitude] }
                           success:^(id responseObject) {
                               NSLog(@"response = %@", responseObject);
                               self.allItems = [self itemsSortedByDistance:[[responseObject objectForKey:@"items"] mutableCopy]];
                               [self setupMapView];
                               requestMade = NO;
                               [self.tableView reloadData];
                           }
                           failure:^(NSError *error) {
                               requestMade = NO;
                               [self.tableView reloadData];
                               NSLog(@"error: %@", [error localizedDescription]);
                           }
     ];
}

- (NSMutableArray*) itemsSortedByDistance:(NSMutableArray*)items {
    [items sortUsingComparator:^NSComparisonResult(id o1, id o2) {
        CLLocation *l1 = [[CLLocation alloc] initWithLatitude:[[o1 objectForKey:@"latitude"] doubleValue] longitude:[[o1 objectForKey:@"longitude"] doubleValue]];
        CLLocation *l2 = [[CLLocation alloc] initWithLatitude:[[o2 objectForKey:@"latitude"] doubleValue] longitude:[[o2 objectForKey:@"longitude"] doubleValue]];
        
        CLLocationDistance d1 = [l1 distanceFromLocation:[LXSession currentLocation]];
        CLLocationDistance d2 = [l2 distanceFromLocation:[LXSession currentLocation]];
        return d1 < d2 ? NSOrderedAscending : d1 > d2 ? NSOrderedDescending : NSOrderedSame;
    }];
    return items;
}

@end
