//
//  SHBucketTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHBucketTableViewCell : UITableViewCell
{
    BOOL onSearchViewController;
}

@property (strong, nonatomic) NSString* bucketLocalKey;
@property (strong, nonatomic) NSString* tagLocalKey;

- (void) configureWithBucketLocalKey:(NSString*)key;
- (void) configureWithBucketLocalKey:(NSString*)key tagLocalKey:(NSString*)tlk;
- (void) configureWithBucketLocalKey:(NSString*)key onSearch:(BOOL)onSearch;

@property (strong, nonatomic) NSMutableArray* collaboratorImages;

@property (strong, nonatomic) UILongPressGestureRecognizer* longPress;

@property (strong, nonatomic) IBOutlet UIView *card;
@property (strong, nonatomic) IBOutlet UILabel *bucketName;
@property (strong, nonatomic) IBOutlet UILabel *bucketItemMessage;

@property (strong, nonatomic) IBOutlet UIView *collaborativeView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collaborativeViewHeightConstraint;
@property (strong, nonatomic) IBOutlet UIView *tagsView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tagsViewHeightConstraint;

@property (strong, nonatomic) NSMutableArray* tagButtons;
@property (strong, nonatomic) NSMutableArray* tagButtonConstraints;

@end
