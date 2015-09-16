//
//  SHItemTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemTableViewCell.h"
#import "SHAssignBucketsViewController.h"
#import "SHSlackThoughtsViewController.h"
#import "HCReminderViewController.h"

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
@synthesize bucketButtons;
@synthesize bucketButtonConstraints;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
}

- (void) refreshedObject:(NSNotification*)notification
{
    if ([[notification userInfo] objectForKey:@"local_key"] && self.itemLocalKey && self.bucketLocalKey && [[[notification userInfo] objectForKey:@"local_key"] isEqualToString:self.itemLocalKey]) {
        //this is a hit, a currently displaying talbeivewcell. reload it.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshVCWithLocalKey" object:nil userInfo:@{@"local_key":self.bucketLocalKey}];
    } else if ([[notification userInfo] objectForKey:@"local_key"] && self.itemLocalKey && [[[notification userInfo] objectForKey:@"local_key"] isEqualToString:self.itemLocalKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshBlankThoughtsVC" object:nil userInfo:nil];
    }
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
    
    //NSLog(@"item: %@", [self.item ID]);
    //NSLog(@"item: %@", self.item);
    
    if (!inverted && self.shouldInvert) {
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        inverted = YES;
    }
    
    [self setMessageText];
    
    [self addMessageTrailingSpaceConstraint];
    
    self.nudgeImageViewTrailingSpace.constant = 6.0f;
    self.outstandingDotTrailingSpace.constant = 5.0f;
    if ([self.item hasReminder]) {
        self.outstandingDotTrailingSpace.constant = 5.0f;
        [self.nudgeImageView setHidden:NO];
    } else {
        [self.nudgeImageView setHidden:YES];
    }
    
    if ([self.item isOutstanding]) {
        [outstandingDot setBackgroundColor:[UIColor SHBlue]];
        [outstandingDot.layer setCornerRadius:4];
        [outstandingDot setClipsToBounds:YES];
        [outstandingDot setHidden:NO];
        self.nudgeImageViewTrailingSpace.constant = 14.0f;
    } else {
        [outstandingDot setHidden:YES];
    }
    
    if (![self.item belongsToCurrentUser] || ([self bucket] && [[self bucket] isCollaborativeThread])) {
        self.avatarHeightConstraint.constant = AVATAR_DIMENSION;
        [self.avatarView setHidden:NO];
        [self.avatarView loadInImageWithRemoteURL:[self.item avatarURLString] localURL:nil];
    } else {
        self.avatarHeightConstraint.constant = 0.0f;
        [self.avatarView setHidden:YES];
    }
    
    [self handleMediaViews];
    
    [self handleBucketButtons];
    
    [self setNeedsLayout];
}

- (void) setMessageText
{
    NSString* text = [self.item message];
    NSMutableAttributedString* as = [[NSMutableAttributedString alloc] initWithString:text];
    for (NSString* link in [self.item links]) {
        NSRange range = [text rangeOfString:link];
        if (range.length > 0) {
            //[as addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:range];
            //[as addAttribute:NSUnderlineColorAttributeName value:[UIColor SHBlue] range:range];
            [as addAttribute:NSForegroundColorAttributeName value:[UIColor SHBlue] range:range];
        }
    }
    [self.message setAttributedText:as];
}

- (UIImageView*) imageViewForMedium:(NSMutableDictionary*)medium
{
    UIImageView* iv = [[UIImageView alloc] init];
    
    [iv setContentMode:UIViewContentModeScaleAspectFill];
    [iv setClipsToBounds:YES];
    [iv setTranslatesAutoresizingMaskIntoConstraints:NO];
    [iv setBackgroundColor:[UIColor SHLightGray]];
    
    iv.layer.cornerRadius = 3.0f;
    [iv.layer setBorderWidth:1.0f];
    [iv.layer setBorderColor:[UIColor SHLightGray].CGColor];
    //[self addActivityIndicatorToView:iv];
    
    return iv;
}

- (void) loadInImageForImageView:(UIImageView*)iv andMedium:(NSMutableDictionary*)medium
{
    NSString* croppedMediaURL = [medium mediaThumbnailURLWithScreenWidth];
    NSLog(@"url: %@", croppedMediaURL);
    
    [iv loadInImageWithRemoteURL:croppedMediaURL localURL:[medium objectForKey:@"local_file_path"]];
}








# pragma mark MGSwipeDelegate

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    if (direction == MGSwipeDirectionLeftToRight) {
        UINavigationController* nc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"navigationHCReminderViewController"];
        HCReminderViewController* vc = [[nc viewControllers] firstObject];
        [vc setLocalKey:self.itemLocalKey];
        UIView* backgroundFrame = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:NO];
        [backgroundFrame setAlpha:0.5f];
        [vc.view setBackgroundColor:[UIColor blackColor]];
        [vc.view addSubview:backgroundFrame];
        [vc.view sendSubviewToBack:backgroundFrame];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"presentViewController" object:nil userInfo:@{@"viewController":nc,@"animated":@NO}];
    } else if (direction == MGSwipeDirectionRightToLeft) {
        UINavigationController* nc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"navigationSHAssignBucketsViewController"];
        SHAssignBucketsViewController* vc = [[nc viewControllers] firstObject];
        [vc setLocalKey:self.itemLocalKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"presentViewController" object:nil userInfo:@{@"viewController":nc,@"animated":@NO}];
    }
    return YES;
}


# pragma mark actions

- (IBAction)longPressAction:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan){
        UINavigationController* nc = [[UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"navigationSHAssignBucketsViewController"];
        SHAssignBucketsViewController* vc = [[nc viewControllers] firstObject];
        [vc setLocalKey:self.itemLocalKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"presentViewController" object:nil userInfo:@{@"viewController":nc}];
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

- (void) handleBucketButtons
{
    [self deleteBucketButtons];
    if ((![self bucket] || [[self bucket] isAllThoughtsBucket]) && [self.item bucketsArray]) {
        [self createBucketButtons];
    }
}

- (void) createBucketButtons
{
    self.bucketButtons = [[NSMutableArray alloc] init];
    self.bucketButtonConstraints = [[NSMutableArray alloc] init];
    
    NSInteger count = 0;
    for (NSMutableDictionary* bucketStub in [self.item bucketsArray]) {
        
        //NSLog(@"bucketsArray: %@", bucketStub);
        
        if ([[bucketStub objectForKey:@"authorized_user_ids"] containsObject:[[[LXSession thisSession] user] ID]]) {
            UIButton* button = [self buttonForBucket:bucketStub];
            [button setTag:count];
            
            [self.contentView addSubview:button];
            [self.bucketButtons addObject:button];
        }
        
        ++count;
        
    }
    
    [self layoutButtons];
}

- (UIButton*) buttonForBucket:(NSMutableDictionary*)bucket
{
    bucket = [LXObjectManager objectWithLocalKey:[bucket localKey]];
    
    UIButton* button = [[UIButton alloc] init];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [button setTitle:[NSString stringWithFormat:@"   %@   ", [bucket firstName]] forState:UIControlStateNormal];
    
    [button setBackgroundColor:[bucket bucketColor]];
    [[button titleLabel] setFont:[UIFont secondaryFontWithSize:12.0f]];
    [button.layer setCornerRadius:10];
    [button setClipsToBounds:YES];
    [button setShowsTouchWhenHighlighted:YES];
    
    [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:20.0] toView:button];
    [button invalidateIntrinsicContentSize];
    
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void) buttonTapped:(UIButton*)sender
{
    if ([sender tag] < [[[self item] bucketsArray] count]) {
        NSMutableDictionary* bucket = [[[self item] bucketsArray] objectAtIndex:[sender tag]];
        [[NSNotificationCenter defaultCenter] postNotificationName:([self bucket] ? @"pushBucketViewController" : @"searchPushBucketViewController") object:nil userInfo:@{@"bucket":bucket}];
    }
}

- (void) layoutButtons
{
    NSInteger index = 0;
    for (UIButton* button in self.bucketButtons) {
        //left align
        if (index == 0) {
            [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeLeft multiplier:1 constant:0] toView:self.contentView];
        } else {
            [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:[self.bucketButtons objectAtIndex:(index-1)] attribute:NSLayoutAttributeTrailing multiplier:1 constant:6] toView:self.contentView];
        }
        
        //top align
        [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.message attribute:NSLayoutAttributeBottom multiplier:1 constant:10] toView:self.contentView];
        if (self.mediaViews && [self.mediaViews count] > 0) {
            [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:[self.mediaViews lastObject] attribute:NSLayoutAttributeBottom multiplier:1 constant:10] toView:self.contentView];
        }
        
        //bottom
        [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:[self contentView] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:button attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:18] toView:self.contentView];
        
        ++index;
    }
}

- (void) deleteBucketButtons
{
    for (UIView* bucketButton in self.bucketButtons) {
        [bucketButton removeFromSuperview];
    }
    self.bucketButtons = nil;
    
    for (NSLayoutConstraint* constraint in self.bucketButtonConstraints) {
        [self.contentView removeConstraint:constraint];
    }
    self.bucketButtonConstraints = nil;
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
        
        if ([self.item hasMessage]) {
            //fill right 1/3 with the image.
            //right align the message label with the image label
            
            [self removeMessageTrailingSpaceConstraint];
            //label to image
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.message attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeLeading multiplier:1 constant:-10] toView:self.contentView];
            //ratio tied to height
            [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeWidth multiplier:(1.0/[medium mediaSizeRatio]) constant:0] toView:self.contentView];
            //heights
            NSArray* constrains = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-18-[imageView]-(>=18)-|"] options:0 metrics:nil views:@{@"imageView":iv}];
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
            [self addConstraint:[NSLayoutConstraint constraintWithItem:[self contentView] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:iv attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:18] toView:self.contentView];
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
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:(count > 0 ? [self.mediaViews objectAtIndex:(count-1)] : self.message) attribute:(count == 0 && ![self.item hasMessage] ? NSLayoutAttributeTop : NSLayoutAttributeBottom) multiplier:1 constant:6] toView:self.contentView];
                        //left
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeLeft multiplier:1 constant:0] toView:self.contentView];
                        //bottom
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:[self contentView] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:iv attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:18] toView:self.contentView];
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
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:(count > 0 ? [self.mediaViews objectAtIndex:(count-1)] : self.message) attribute:(count == 0 && ![self.item hasMessage] ? NSLayoutAttributeTop : NSLayoutAttributeBottom) multiplier:1 constant:6] toView:self.contentView];
                        //left
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.message attribute:NSLayoutAttributeLeft multiplier:1 constant:0] toView:self.contentView];
                        //bottom
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:[self contentView] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:iv attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:18] toView:self.contentView];
                        
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

- (void) addButtonConstraint:(NSLayoutConstraint *)constraint toView:(UIView*)view
{
    [view addConstraint:constraint];
    [self.bucketButtonConstraints addObject:constraint];
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
