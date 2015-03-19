//
//  HCLocationNotesViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#define PICTURE_HEIGHT 280
#define PICTURE_MARGIN_TOP 8

@interface HCLocationNotesViewController : UIViewController <MKMapViewDelegate>
{
    BOOL requestMade;
    BOOL firstRequest;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *allItems;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end
