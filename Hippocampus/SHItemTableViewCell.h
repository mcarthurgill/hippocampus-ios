//
//  SHItemTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHItemTableViewCell : MGSwipeTableCell <MGSwipeTableCellDelegate>
{
    BOOL inverted;
}

@property (nonatomic) BOOL shouldInvert;

- (void) configureWithItem:(NSMutableDictionary*)item bucketLocalKey:(NSString*)bucketKey;
- (void) configureWithItemLocalKey:(NSString*)key bucketLocalKey:(NSString*)bucketKey;
- (void) configureWithItemLocalKey:(NSString*)key;

@property (strong, nonatomic) NSString* itemLocalKey;
@property (strong, nonatomic) NSString* bucketLocalKey;
@property (strong, nonatomic) NSMutableDictionary* item;

@property (strong, nonatomic) NSMutableArray* mediaViews;
@property (strong, nonatomic) NSMutableArray* mediaUsed;
@property (strong, nonatomic) NSMutableArray* addedConstraints;

@property (strong, nonatomic) NSMutableArray* bucketButtons;
@property (strong, nonatomic) NSMutableArray* bucketButtonConstraints;

@property (strong, nonatomic) IBOutlet UILabel *message;
@property (strong, nonatomic) IBOutlet UILabel *outstandingDot;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outstandingDotTopToImage;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outstandingDotTrailingSpace;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *messageTrailingSpace;
@property (strong, nonatomic) IBOutlet UIImageView *nudgeImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nudgeImageViewTrailingSpace;
@property (strong, nonatomic) IBOutlet UIImageView *avatarView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *avatarHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *avatarWidthConstraint;

@property (strong, nonatomic) UILongPressGestureRecognizer* longPress;

- (IBAction) longPressAction:(UILongPressGestureRecognizer*)sender;

@end
