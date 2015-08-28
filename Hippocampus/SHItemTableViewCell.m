//
//  SHItemTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemTableViewCell.h"


#define IMAGE_FADE_IN_TIME 0.4f
#define PICTURE_HEIGHT 100
#define PICTURE_MARGIN_TOP 8.0f
#define AVATAR_DIMENSION 32.0f


@implementation SHItemTableViewCell

@synthesize shouldInvert;
@synthesize itemLocalKey;
@synthesize bucketLocalKey;
@synthesize item;
@synthesize message;
@synthesize nudgeImageView, nudgeImageViewTrailingSpace;
@synthesize messageTrailingSpace;
@synthesize outstandingDot, outstandingDotTopToImage, outstandingDotTrailingSpace;
@synthesize longPress;
@synthesize mediaViews;
@synthesize mediaUsed;
@synthesize avatarView;
@synthesize avatarHeightConstraint, avatarWidthConstraint;


- (void)awakeFromNib
{
    // Initialization code
    inverted = NO;
    self.shouldInvert = YES;
    
    [self setupAppearanceSettings];
    [self setupGestureRecognizers];
    [self setupSwipeButtons];
    
}



# pragma mark setup

- (void) setupAppearanceSettings
{
    [self.message setFont:[UIFont itemContentFont]];
    [self.message setTextColor:[UIColor SHFontDarkGray]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.avatarView.layer setCornerRadius:(AVATAR_DIMENSION/2.0f)];
    [self.avatarView setClipsToBounds:YES];
    [self.avatarView setBackgroundColor:[UIColor SHLightGray]];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) setupSwipeButtons
{
    //configure left buttons
    self.leftButtons = @[[MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"nudge_icon_white_swipe.png"] backgroundColor:[UIColor SHGreen]]];
    self.leftSwipeSettings.transition = MGSwipeTransitionBorder;
    self.leftExpansion.buttonIndex = 0;
    self.leftExpansion.fillOnTrigger = NO;
    self.leftExpansion.threshold = 1.0f;
    
    //configure right buttons
    self.rightButtons = @[[MGSwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"plus_icon_white_swipe.png"] backgroundColor:[UIColor SHBlue]]];
    self.rightSwipeSettings.transition = MGSwipeTransitionBorder;
    self.rightExpansion.buttonIndex = 0;
    self.rightExpansion.fillOnTrigger = NO;
    self.rightExpansion.threshold = 1.0f;
    
    [self setDelegate:self];
}

- (void) setupGestureRecognizers
{
    if (!self.longPress) {
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self addGestureRecognizer:longPress];
    }
}



- (NSMutableDictionary*) bucket
{
    return self.bucketLocalKey ? [LXObjectManager objectWithLocalKey:self.bucketLocalKey] : nil;
}



# pragma mark configure

- (void) configureWithItemLocalKey:(NSString*)key
{
    [self configureWithItemLocalKey:key bucketLocalKey:nil];
}

- (void) configureWithItemLocalKey:(NSString*)key bucketLocalKey:(NSString*)bucketKey
{
    [self configureWithItem:[LXObjectManager objectWithLocalKey:key] bucketLocalKey:bucketKey];
}

- (void) configureWithItem:(NSMutableDictionary*)i bucketLocalKey:(NSString*)bucketKey
{
    [self setItem:i];
    [self setItemLocalKey:[self.item localKey]];
    [self setBucketLocalKey:bucketKey];
    
    NSLog(@"%@:%@|", [self.item ID], [self.item message]);
    
    if (!inverted && self.shouldInvert) {
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        inverted = YES;
    }
    
    [self.message setText:[item message]];
    [self addMessageTrailingSpaceConstraint];
    
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
    
    if (![item belongsToCurrentUser] || ([self bucket] && [[self bucket] isCollaborativeThread])) {
        self.avatarHeightConstraint.constant = AVATAR_DIMENSION;
        [self.avatarView setHidden:NO];
        
        if ([SGImageCache haveImageForURL:[item avatarURLString]]) {
            self.avatarView.image = [SGImageCache imageForURL:[item avatarURLString]];
            [self.avatarView setAlpha:1.0f];
            [self.avatarView viewWithTag:1].alpha = 0.0;
            [[self.avatarView viewWithTag:1] removeFromSuperview];
        } else if (![self.avatarView.image isEqual:[SGImageCache imageForURL:[item avatarURLString]]]) {
            self.avatarView.image = nil;
            [self.avatarView setAlpha:1.0f];
            [SGImageCache getImageForURL:[item avatarURLString]].then(^(UIImage* image) {
                if (image) {
                    float curAlpha = [self.avatarView alpha];
                    [self.avatarView setAlpha:0.0f];
                    self.avatarView.image = image;
                    [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void){
                        [self.avatarView setAlpha:curAlpha];
                        [self.avatarView viewWithTag:1].alpha = 0.0;
                        [[self.avatarView viewWithTag:1] removeFromSuperview];
                    }];
                }
            });
        }
    } else {
        self.avatarHeightConstraint.constant = 0.0f;
        [self.avatarView setHidden:YES];
    }
    
    [self handleMediaViews];
    
    [self setNeedsLayout];
}

- (UIImageView*) imageViewForMedium:(NSMutableDictionary*)medium
{
    UIImageView* iv = [[UIImageView alloc] init];
    
    [iv setContentMode:UIViewContentModeScaleAspectFill];
    [iv setClipsToBounds:YES];
    [iv setTranslatesAutoresizingMaskIntoConstraints:NO];
    [iv setBackgroundColor:[UIColor SHLightGray]];
    //[self addActivityIndicatorToView:iv];
    
    return iv;
}

- (void) loadInImageForImageView:(UIImageView*)iv andMedium:(NSMutableDictionary*)medium
{
    if ([medium hasID]) {
        
        NSString* croppedMediaURL = [medium mediaThumbnailURLWithScreenWidth];
        NSLog(@"url: %@", croppedMediaURL);
        
        if ([SGImageCache haveImageForURL:croppedMediaURL]) {
            iv.image = [SGImageCache imageForURL:croppedMediaURL];
            [iv setAlpha:1.0f];
            [iv viewWithTag:1].alpha = 0.0;
            [[iv viewWithTag:1] removeFromSuperview];
        } else if (![iv.image isEqual:[SGImageCache imageForURL:croppedMediaURL]]) {
            iv.image = nil;
            [iv setAlpha:1.0f];
            [SGImageCache getImageForURL:croppedMediaURL].then(^(UIImage* image) {
                if (image) {
                    float curAlpha = [iv alpha];
                    [iv setAlpha:0.0f];
                    iv.image = image;
                    [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void){
                        [iv setAlpha:curAlpha];
                        [iv viewWithTag:1].alpha = 0.0;
                        [[iv viewWithTag:1] removeFromSuperview];
                    }];
                }
            });
        }
        
    } else {
        if ([NSData dataWithContentsOfFile:[medium mediaURL]] && ![iv.image isEqual:[UIImage imageWithData:[NSData dataWithContentsOfFile:[medium mediaURL]]]]) {
            [iv setAlpha:0.0f];
            iv.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:[medium mediaURL]]];
            [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                [iv setAlpha:1.0f];
                [iv viewWithTag:1].alpha = 0.0;
            }];
        }
    }
}








# pragma mark MGSwipeDelegate

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    if (direction == MGSwipeDirectionLeftToRight) {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Set a nudge!" message:[NSString stringWithFormat:@"%@", [LXObjectManager objectWithLocalKey:self.itemLocalKey]] delegate:self cancelButtonTitle:@"Cool." otherButtonTitles:nil];
        [av show];
    } else if (direction == MGSwipeDirectionRightToLeft) {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Assign!" message:[NSString stringWithFormat:@"%@", [LXObjectManager objectWithLocalKey:self.itemLocalKey]] delegate:self cancelButtonTitle:@"Cool." otherButtonTitles:nil];
        [av show];
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



# pragma mark constrains

- (void) removeMessageTrailingSpaceConstraint
{
    if (self.messageTrailingSpace) {
        [self.contentView removeConstraint:self.messageTrailingSpace];
        self.messageTrailingSpace = nil;
    }
}

- (void) addMessageTrailingSpaceConstraint
{
    if (!self.messageTrailingSpace) {
        self.messageTrailingSpace = [NSLayoutConstraint constraintWithItem:self.message attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:[self contentView] attribute:NSLayoutAttributeTrailingMargin multiplier:1 constant:-12];
        [self.contentView addConstraint:self.messageTrailingSpace];
    }
}

- (void) handleMediaViews
{
    [self deleteMediaViews];
    if ([[LXObjectManager objectWithLocalKey:self.itemLocalKey] hasMedia]) {
        [self createMediaViews];
    }
}

- (void) createMediaViews
{
    self.mediaViews = [[NSMutableArray alloc] init];
    self.mediaUsed = [[NSMutableArray alloc] init];
    self.addedConstraints = [[NSMutableArray alloc] init];
    
    NSInteger count = 0;
    for (NSMutableDictionary* medium in [[LXObjectManager objectWithLocalKey:self.itemLocalKey] media]) {
        
        if ([medium width] > 0.0 && [medium height] > 0.0) {
            [self.mediaUsed addObject:medium];
            
            UIImageView* iv = [self imageViewForMedium:medium];
            [self.contentView addSubview:iv];
            [self.mediaViews addObject:iv];
            [self loadInImageForImageView:iv andMedium:medium];
            
            ++count;
        }
        
    }
    
    [self layoutMedia];
}

- (void) deleteMediaViews
{
    for (UIView* mediaView in self.mediaViews) {
        [mediaView removeFromSuperview];
    }
    self.mediaViews = nil;
    
    for (NSLayoutConstraint* constraint in self.addedConstraints) {
        [self.contentView removeConstraint:constraint];
    }
    self.addedConstraints = nil;
}


- (void) layoutMedia
{
    if ([self.mediaViews count] == 1) {
        UIImageView* iv = [self.mediaViews firstObject];
        NSMutableDictionary* medium = [self.mediaUsed firstObject];
        
        if ([item hasMessage]) {
            //fill right 1/3 with the image.
            //right align the message label with the image label
            
            [self removeMessageTrailingSpaceConstraint];
            //label to image
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.message attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeLeading multiplier:1 constant:-10] toView:self.contentView];
            //ratio tied to height
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeWidth multiplier:(1.0/[medium mediaSizeRatio]) constant:0] toView:self.contentView];
            //heights
            NSArray* constrains = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-10-[imageView]-(>=10)-|"] options:0 metrics:nil views:@{@"imageView":iv}];
            [self.contentView addConstraints:constrains];
            [self.addedConstraints addObjectsFromArray:constrains];
            //right
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:[self contentView] attribute:NSLayoutAttributeTrailingMargin multiplier:1 constant:-12] toView:self.contentView];
            //ratio tied to width
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeWidth multiplier:(2.0/5.0) constant:0] toView:self.contentView];
            
            
        } else {
            //fill width of cell, match left and right with the message label
            
            //ratio
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeWidth multiplier:(1.0/[medium mediaSizeRatio]) constant:0] toView:self.contentView];
            //top
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeTop multiplier:1 constant:0] toView:self.contentView];
            //right
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeRight multiplier:1 constant:0] toView:self.contentView];
            //left
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeLeft multiplier:1 constant:0] toView:self.contentView];
            //bottom
            [self addConstraint:[NSLayoutConstraint constraintWithItem:[self contentView] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:iv attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:10] toView:self.contentView];
        }
    } else if ([self.mediaViews count] > 1) {
        
        //multiple medias
        for (NSInteger count = 0; count < [self.mediaViews count]; nil) {
            
            if (([self.mediaViews count]-count) == 3) {
                
                //line up the remaining three
                for (NSInteger i = 0; i < 3; i++) {
                    
                    NSMutableDictionary* medium = [self.mediaUsed objectAtIndex:(count+i)];
                    UIImageView* iv = [self.mediaViews objectAtIndex:(count+i)];
                    
                    //fill width of cell, match left and right with the message label
                    
                    //ratio
                    [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeWidth multiplier:(1.0/[medium mediaSizeRatio]) constant:0] toView:self.contentView];
                    
                    if (i == 0) {
                        //leftmost image
                        
                        //top
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:(count > 0 ? [self.mediaViews objectAtIndex:(count-1)] : self.message) attribute:(count == 0 && ![item hasMessage] ? NSLayoutAttributeTop : NSLayoutAttributeBottom) multiplier:1 constant:6] toView:self.contentView];
                        //left
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeLeft multiplier:1 constant:0] toView:self.contentView];
                        //bottom
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:[self contentView] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:iv attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:10] toView:self.contentView];
                    } else if (i == 1) {
                        // center image
                        
                        //top
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:count] attribute:NSLayoutAttributeTop multiplier:1 constant:0] toView:self.contentView];
                        //left
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:count] attribute:NSLayoutAttributeTrailing multiplier:1 constant:6] toView:self.contentView];
                        //bottom
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:count] attribute:NSLayoutAttributeBottom multiplier:1 constant:0] toView:self.contentView];
                        
                    } else {
                        //right image
                        
                        //top
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:(count+1)] attribute:NSLayoutAttributeTop multiplier:1 constant:0] toView:self.contentView];
                        //left
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:(count+1)] attribute:NSLayoutAttributeTrailing multiplier:1 constant:6] toView:self.contentView];
                        //bottom
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:(count+1)] attribute:NSLayoutAttributeBottom multiplier:1 constant:0] toView:self.contentView];
                        //right
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeRight multiplier:1 constant:0] toView:self.contentView];
                        
                    }
                    
                }
                
                count = count+3;
                
            } else {
                
                //line up the next two
                for (NSInteger i = 0; i < 2; i++) {
                    
                    NSMutableDictionary* medium = [self.mediaUsed objectAtIndex:(count+i)];
                    UIImageView* iv = [self.mediaViews objectAtIndex:(count+i)];
                    
                    //ratio
                    [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeWidth multiplier:(1.0/[medium mediaSizeRatio]) constant:0] toView:self.contentView];
                    
                    if (i == 0) {
                        //leftmost image
                        
                        //top
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:(count > 0 ? [self.mediaViews objectAtIndex:(count-1)] : self.message) attribute:(count == 0 && ![item hasMessage] ? NSLayoutAttributeTop : NSLayoutAttributeBottom) multiplier:1 constant:6] toView:self.contentView];
                        //left
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeLeft multiplier:1 constant:0] toView:self.contentView];
                        //bottom
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:[self contentView] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:iv attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:10] toView:self.contentView];
                        
                    } else {
                        //right image
                        
                        //top
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:(count)] attribute:NSLayoutAttributeTop multiplier:1 constant:0] toView:self.contentView];
                        //left
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:(count)] attribute:NSLayoutAttributeTrailing multiplier:1 constant:6] toView:self.contentView];
                        //bottom
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self.mediaViews objectAtIndex:(count)] attribute:NSLayoutAttributeBottom multiplier:1 constant:0] toView:self.contentView];
                        //right
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeRight multiplier:1 constant:0] toView:self.contentView];
                    }
                    
                }
                
                count = count+2;
                
            }
        }
    }
}

- (void) addConstraint:(NSLayoutConstraint *)constraint toView:(UIView*)view
{
    [view addConstraint:constraint];
    [self.addedConstraints addObject:constraint];
}

- (void) addActivityIndicatorToView:(UIView*)view
{
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.alpha = 1.0;
    [view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    [activityIndicator setTag:1];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0] toView:view];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0] toView:view];
}

@end
