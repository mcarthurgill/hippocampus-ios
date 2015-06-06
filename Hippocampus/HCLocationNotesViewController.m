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
#define TRUNCATED_TITLE_LENGTH 100
#define NUMBER_ITEMS_RETURNED 512

@interface HCLocationNotesViewController ()

@end

@implementation HCLocationNotesViewController

@synthesize sections;
@synthesize allItems;
@synthesize mapViewHeightConstraint;
@synthesize tableViewHeightConstraint;
@synthesize mapView;

@synthesize includedItems;

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
    self.includedItems = [[NSMutableDictionary alloc] init];
    self.includedItemsByCoordinateTag = [[NSMutableDictionary alloc] init];
    
    [self.navigationItem setTitle:@"Thoughts Nearby"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setupMapView];
    [self getItemsNearCurrentLocation];
}

# pragma mark - Create and Setup MapView

- (void) setupMapView
{
    [self.mapView setDelegate:self];
    [self setupMapAndTableConstraints];
    [self makeMapViewVisible];
}

- (void) addAnnotationsToMapView:(NSArray*)items
{
    for (NSDictionary *item in items) {
        [self addAnnotationToMapView:item];
    }
}

- (void) addAnnotationToMapView:(NSDictionary*)item
{
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:[item location].coordinate];
    [annotation setTitle:[[item message] truncated:TRUNCATED_TITLE_LENGTH]];
    [self.mapView addAnnotation:annotation];
}

- (void) removeAllAnnotationsFromMapView
{
    for (MKPointAnnotation* a in [self.mapView annotations]) {
        [self.mapView removeAnnotation:a];
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
    NSDictionary* item = [self itemWithMessage:[annotation title] truncated:TRUNCATED_TITLE_LENGTH];
    if (item) {
        rightButton.tag = [[item ID] integerValue];
    }
    if (rightButton.tag >= 0) {
        customPinView.rightCalloutAccessoryView = rightButton;
    }
    return customPinView;
}

- (void) showItem:(UIButton*)sender
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCContainerViewController* itvc = (HCContainerViewController*)[storyboard instantiateViewControllerWithIdentifier:@"containerViewController"];
    NSMutableDictionary* item = [[self.includedItems objectForKey:[NSString stringWithFormat:@"%li",(long)sender.tag]] mutableCopy];
    [itvc setItem:item];
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

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"all"]) {
        NSDictionary *item = [self.allItems objectAtIndex:indexPath.row];
        return [HCItemTableViewCell heightForCellWithItem:item];
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
    ASAPIClient *apiClient = [ASAPIClient apiClientWithApplicationID:@"FVGQB7HR19" apiKey:@"ddecc3b35feb56ab0a9d2570ac964a82"];
    ASRemoteIndex *index = [apiClient getIndex:@"Item"];
    ASQuery* query = [[ASQuery alloc] init];
    [query searchInsideBoundingBoxWithLatitudeP1:centery-dy longitudeP1:centerx-dx latitudeP2:centery+dy longitudeP2:centerx+dx];
    query.numericFilters = [NSString stringWithFormat:@"user_ids_array=%@", [[[LXSession thisSession] user] userID]];
    query.hitsPerPage = NUMBER_ITEMS_RETURNED;
    [index search:query
          success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *answer) {
              requestMade = NO;
              [self addItems:[answer objectForKey:@"hits"]];
              [self.tableView reloadData];
          } failure:^(ASRemoteIndex*index, ASQuery *query, NSString* errorMessage) {
              requestMade = NO;
              [self.tableView reloadData];
          }
     ];
}



- (void) requestItemsNearMeFromServer
{
    requestMade = YES;
    ASAPIClient *apiClient = [ASAPIClient apiClientWithApplicationID:@"FVGQB7HR19" apiKey:@"ddecc3b35feb56ab0a9d2570ac964a82"];
    ASRemoteIndex *index = [apiClient getIndex:@"Item"];
    ASQuery* query = [[ASQuery alloc] init];
    if (![[LXSession thisSession] locationPermissionDetermined]) {
        [query searchAroundLatitudeLongitudeViaIP:10000];
    } else {
        CLLocation *loc = [LXSession currentLocation];
        [query searchAroundLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude maxDist:10000];
        self.mapView.region = MKCoordinateRegionMakeWithDistance(loc.coordinate, 10000, 10000);
    }
    query.numericFilters = [NSString stringWithFormat:@"user_ids_array=%@", [[[LXSession thisSession] user] userID]];
    query.hitsPerPage = NUMBER_ITEMS_RETURNED;
    [index search:query
          success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *answer) {
              firstRequest = NO;
              requestMade = NO;
              [self addItems:[answer objectForKey:@"hits"]];
              [self.tableView reloadData];
          } failure:^(ASRemoteIndex*index, ASQuery *query, NSString* errorMessage) {
              requestMade = NO;
              [self.tableView reloadData];
          }
     ];
}



- (void) getItemsNearCurrentLocation
{
    if (![[LXSession thisSession] locationPermissionDetermined]) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCPermissionViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"permissionViewController"];
        [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
        [vc setImageForMainImageView:[UIImage imageNamed:@"permission-screen.jpg"]];
        [vc setMainLabelText:@"Use your phone's location to see your thoughts on a map."];
        [vc setPermissionType:@"location"];
        [vc setDelegate:self];
        [vc setButtonText:@"Grant Location Permission"];
        [self.navigationController presentViewController:vc animated:NO completion:nil];
    }
    [self requestItemsNearMeFromServer];
}



- (void) permissionsDelegate
{
    [self requestItemsNearMeFromServer];
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


- (void) addItems:(NSArray*)items
{
    NSUInteger index = 0;
    for (NSDictionary* i in items) {
        if (![self.includedItems objectForKey:[NSString stringWithFormat:@"%@",[i ID]]]) {
            [self.includedItems setObject:i forKey:[NSString stringWithFormat:@"%@",[i ID]]];
            //[self.includedItemsByCoordinateTag setObject:i forKey:[i latLongKey]];
            [self.allItems insertObject:i atIndex:index];
            [self addAnnotationToMapView:i];
            ++index;
        }
    }
}





# pragma mark - Helpers

- (NSDictionary*) itemWithMessage:(NSString*)message truncated:(int)truncation
{
    for (NSDictionary *item in self.allItems) {
        if ([[[item objectForKey:@"message"] truncated:truncation] isEqualToString:message]) {
            return item;
        }
    }
    return nil;
}





# pragma mark item cell callback

- (void) actionTaken:(NSString *)action forItem:(NSDictionary *)i newItem:(NSMutableDictionary *)newI
{
    NSLog(@"actionTaken callback: %@", action);
    if ([action isEqualToString:@"delete"]) {
        [self.allItems removeObject:i];
        [self.tableView reloadData];
    } else if ([action isEqualToString:@"setReminder"]) {
        [self.allItems replaceObjectAtIndex:[self.allItems indexOfObject:i] withObject:newI];
        [self.tableView reloadData];
    } else if ([action isEqualToString:@"addToStack"]) {
        [self.allItems replaceObjectAtIndex:[self.allItems indexOfObject:i] withObject:newI];
        [self.tableView reloadData];
    }
}

@end
