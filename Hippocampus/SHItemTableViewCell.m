//
//  SHItemTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemTableViewCell.h"

@implementation SHItemTableViewCell

@synthesize itemLocalKey;
@synthesize message;
@synthesize nudgeImageView, nudgeImageViewTrailingSpace;
@synthesize outstandingDot, outstandingDotTopToImage, outstandingDotTrailingSpace;
@synthesize longPress;

- (void)awakeFromNib
{
    // Initialization code
    inverted = NO;
    [self setupGestureRecognizers];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) configureWithItem:(NSMutableDictionary*)item
{
    [self setItemLocalKey:[item localKey]];
    
    [self setupSwipeButtons];
    
    [self.message setFont:[UIFont itemContentFont]];
    [self.message setText:[item message]];
    
    self.nudgeImageViewTrailingSpace.constant = 6.0f;
    self.outstandingDotTrailingSpace.constant = 5.0f;
    if ([item hasReminder]) {
        self.outstandingDotTrailingSpace.constant = 5.0f;
        [self.nudgeImageView setHidden:NO];
    } else {
        [self.nudgeImageView setHidden:YES];
    }
    
    if ([item isOutstanding]) {
        [outstandingDot setBackgroundColor:[UIColor SHBlue]];
        [outstandingDot.layer setCornerRadius:4];
        [outstandingDot setClipsToBounds:YES];
        [outstandingDot setHidden:NO];
        self.nudgeImageViewTrailingSpace.constant = 14.0f;
    } else {
        [outstandingDot setHidden:YES];
    }
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    if (!inverted) {
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        inverted = YES;
    }
}

- (void) setupSwipeButtons
{
    if ([[LXObjectManager objectWithLocalKey:self.itemLocalKey] belongsToCurrentUser]) {
        //configure right buttons
        self.rightButtons = @[[MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"trash_icon_white_swipe.png"] backgroundColor:[UIColor SHRed]]];
        self.rightSwipeSettings.transition = MGSwipeTransitionBorder;
        self.rightExpansion.buttonIndex = 0;
        self.rightExpansion.fillOnTrigger = YES;
        self.rightExpansion.threshold = 3.5f;
    } else {
        self.rightButtons = nil;
    }
    
    //configure left buttons
    self.leftButtons = @[[MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"nudge_icon_white_swipe.png"] backgroundColor:[UIColor SHGreen]]];
    self.leftSwipeSettings.transition = MGSwipeTransitionBorder;
    self.leftExpansion.buttonIndex = 0;
    self.leftExpansion.fillOnTrigger = NO;
    self.leftExpansion.threshold = 1.0f;
    
    [self setDelegate:self];
}

- (void) setupGestureRecognizers
{
    if (!self.longPress) {
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self addGestureRecognizer:longPress];
    }
}



# pragma mark MGSwipeDelegate

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    if (direction == MGSwipeDirectionLeftToRight) {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Set a nudge!" message:[NSString stringWithFormat:@"%@", [LXObjectManager objectWithLocalKey:self.itemLocalKey]] delegate:self cancelButtonTitle:@"Cool." otherButtonTitles:nil];
        [av show];
    } else if (direction == MGSwipeDirectionRightToLeft) {
        //UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Delete!" message:[NSString stringWithFormat:@"%@", [LXObjectManager objectWithLocalKey:self.itemLocalKey]] delegate:self cancelButtonTitle:@"Cool." otherButtonTitles:nil];
        //[av show];
        if ([[LXObjectManager objectWithLocalKey:self.itemLocalKey] belongsToCurrentUser]) {
            [[LXObjectManager objectWithLocalKey:self.itemLocalKey] destroyItem];
        } else {
            //not yours!
        }
    }
    return YES;
}


# pragma mark actions

- (IBAction)longPressAction:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan){
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Long press action!" message:[NSString stringWithFormat:@"%@", [LXObjectManager objectWithLocalKey:self.itemLocalKey]] delegate:self cancelButtonTitle:@"Cool." otherButtonTitles:nil];
        [av show];
    }
}

@end
