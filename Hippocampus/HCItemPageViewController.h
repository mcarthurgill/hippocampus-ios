//
//  HCItemPageViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 2/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCItemPageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray* items;
@property (strong, nonatomic) NSMutableDictionary* bucket;
@property (strong, nonatomic) NSMutableDictionary* item;

@property (strong, nonatomic) UINavigationItem* navItem;

- (void) handleInitialLoad;
- (void) saveAction:(id)sender;

- (void) updateItemsArrayWithOriginal:(NSMutableDictionary*)original new:(NSMutableDictionary*)n;

@end
