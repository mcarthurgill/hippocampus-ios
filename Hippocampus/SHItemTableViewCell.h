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

- (void) configureWithItem:(NSMutableDictionary*)item;

@property (strong, nonatomic) NSString* itemLocalKey;

@property (strong, nonatomic) IBOutlet UILabel *message;
@property (strong, nonatomic) IBOutlet UILabel *outstandingDot;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outstandingDotTopToImage;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outstandingDotTrailingSpace;
@property (strong, nonatomic) IBOutlet UIImageView *nudgeImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nudgeImageViewTrailingSpace;

@property (strong, nonatomic) UILongPressGestureRecognizer* longPress;

- (IBAction) longPressAction:(UILongPressGestureRecognizer*)sender;

@end
