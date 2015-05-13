//
//  HCLocationNotesViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCLocationNotesViewController.h"
#import "HCContainerViewController.h"
#import "HCItemTableViewCell.h"
#import "HCIndicatorTableViewCell.h"
#import "HCExplanationTableViewCell.h"
#import "HCPermissionViewController.h"

@import MapKit;

#define IMAGE_FADE_IN_TIME 0.1f
#define PICTURE_HEIGHT_IN_CELL 280
#define PICTURE_MARGIN_TOP_IN_CELL 8


@interface HCLocationNotesViewController ()

@end

@implementation HCLocationNotesViewController

@synthesize sections;
@synthesize allItems;
@synthesize mapViewHeightConstraint;
@synthesize tableViewHeightConstraint;
@synthesize mapView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupProperties];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupProperties
{
    requestMade = NO;
    firstRequest = YES;
    self.allItems = [[NSMutableArray alloc] init];
    [self getItemsNearCurrentLocation];
    [self.navigationItem setTitle:@"Thoughts Nearby"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self setupMapView];
}

# pragma mark - Create and Setup MapView

- (void) setupMapView
{
    [self.mapView setDelegate:self];
    [self setupMapAndTableConstraints];
    [self addAnnotationsToMapView];
    [self makeMapViewVisible];
}

- (void) addAnnotationsToMapView
{
    for (NSDictionary*item in self.allItems) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        [annotation setCoordinate:[item location].coordinate];
        [annotation setTitle:[[item message] truncated:25]];
        [self.mapView addAnnotation:annotation];
    }
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self showItem:(UIButton*)[view rightCalloutAccessoryView]];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (!firstRequest && !requestMade) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self getItemsWithCenterX:self.mapView.region.center.longitude andCenterY:self.mapView.region.center.latitude andDX:self.mapView.region.span.longitudeDelta/2.0 andDY:self.mapView.region.span.latitudeDelta/2.0];
        });
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (annotation == self.mapView.userLocation) {
        return nil;
    }
    
    MKPinAnnotationView* customPinView = [[MKPinAnnotationView alloc]
                                           initWithAnnotation:annotation reuseIdentifier:@"annotation"];
    customPinView.canShowCallout = YES;
    
    UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    rightButton.tag = [self indexOfItemWithMessage:[annotation title] truncated:25];
    if (rightButton.tag >= 0) {
        customPinView.rightCalloutAccessoryView = rightButton;
    }
    return customPinView;
}

- (void) showItem:(UIButton*)sender {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
    [itvc setItem:[self.allItems objectAtIndex:sender.tag]];
    [itvc setItems:self.allItems];
    [itvc setDelegate:self];
    [self.navigationController pushViewController:itvc animated:YES];
}

- (void) setupMapAndTableConstraints
{
    mapViewHeightConstraint.constant = self.view.frame.size.height*0.5;
    tableViewHeightConstraint.constant = self.view.frame.size.height - mapViewHeightConstraint.constant + self.navigationController.navigationBar.frame.size.height;
    
    [UIView animateWithDuration:0.0 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void) makeMapViewVisible
{
    [self.mapView showAnnotations:self.mapView.annotations animated:NO];
}

# pragma mark - TableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    self.sections = [[NSMutableArray alloc] init];
    
    if (requestMade) {
        [self.sections addObject:@"requesting"];
    } else if (self.allItems.count > 0){
        [self.sections addObject:@"all"];
    } else {
        [self.sections addObject:@"explanation"];
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
    NSString *text = [[LXSession thisSession] hasLocation] ? @"You haven't created any notes here." : @"You need to give us location permission for this feature. Settings > Privacy > Location Services > Hippocampus";
    [cell configureWithText:text];
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
            int numImages = 0;
            for (NSString *url in [item mediaURLs]) {
                if ([url isImageUrl]) {
                    numImages++;
                }
            }
            additional = (PICTURE_MARGIN_TOP_IN_CELL+PICTURE_HEIGHT_IN_CELL)*numImages;
        }
        return [self heightForText:[item truncatedMessage] width:(self.view.frame.size.width-40.0f) font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f + additional + 4.0f;
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
        [itvc setItem:[self.allItems objectAtIndex:indexPath.row]];
        [itvc setItems:self.allItems];
        [itvc setDelegate:self];
        [self.navigationController pushViewController:itvc animated:YES];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


# pragma mark - Location Based Notes

- (void) getItemsWithCenterX:(CGFloat)centerx andCenterY:(CGFloat)centery andDX:(CGFloat)dx andDY:(CGFloat)dy
{
    requestMade = YES;
    [[LXServer shared] getItemsNearCenterX:centerx andCenterY:centery andDX:dx andDY:dy success:^(id responseObject) {
        self.allItems = [self itemsSortedByDistance:[[responseObject objectForKey:@"items"] mutableCopy]];
        requestMade = NO;
        [self addAnnotationsToMapView];
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        requestMade = NO;
        [self.tableView reloadData];
    }];
}

- (void) getItemsNearCurrentLocation
{
    if (![LXSession locationPermissionDetermined]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCPermissionViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"permissionViewController"];
        [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
        [vc setImageForMainImageView:[UIImage imageNamed:@"permission-screen.jpg"]];
        [vc setMainLabelText:@"Use your phone's location to see your thoughts on a map."];
        [vc setPermissionType:@"location"];
        [vc setDelegate:self];
        [vc setButtonText:@"Grant Location Permission"];
        [self.navigationController presentViewController:vc animated:NO completion:nil];
    } else {
        [self requestItemsNearMeFromServer];
    }
}

- (void) permissionsDelegate
{
    [self requestItemsNearMeFromServer]; 
}

- (void) requestItemsNearMeFromServer
{
    requestMade = YES;
    [[LXServer shared] getItemsNearCurrentLocation:^(id responseObject) {
        firstRequest = NO;
        self.allItems = [self itemsSortedByDistance:[[responseObject objectForKey:@"items"] mutableCopy]];
        requestMade = NO;
        [self setupMapView];
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        requestMade = NO;
        [self.tableView reloadData];
    }];
}

- (NSMutableArray*) itemsSortedByDistance:(NSMutableArray*)items
{
    [items sortUsingComparator:^NSComparisonResult(id o1, id o2) {
        CLLocation *l1 = [[CLLocation alloc] initWithLatitude:[[o1 objectForKey:@"latitude"] doubleValue] longitude:[[o1 objectForKey:@"longitude"] doubleValue]];
        CLLocation *l2 = [[CLLocation alloc] initWithLatitude:[[o2 objectForKey:@"latitude"] doubleValue] longitude:[[o2 objectForKey:@"longitude"] doubleValue]];
        
        CLLocationDistance d1 = [l1 distanceFromLocation:[LXSession currentLocation]];
        CLLocationDistance d2 = [l2 distanceFromLocation:[LXSession currentLocation]];
        return d1 < d2 ? NSOrderedAscending : d1 > d2 ? NSOrderedDescending : NSOrderedSame;
    }];
    return items;
}


# pragma mark - Helpers
- (NSUInteger) indexOfItemWithMessage:(NSString*)message truncated:(int)truncation
{
    for (NSDictionary *item in self.allItems) {
        if ([[[item objectForKey:@"message"] truncated:truncation] isEqualToString:message]) {
            return [self.allItems indexOfObject:item];
        }
    }
    return -1;
}

@end
