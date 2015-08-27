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


@implementation SHItemTableViewCell

@synthesize itemLocalKey;
@synthesize message;
@synthesize nudgeImageView, nudgeImageViewTrailingSpace;
@synthesize outstandingDot, outstandingDotTopToImage, outstandingDotTrailingSpace;
@synthesize longPress;
@synthesize mediaViews;



- (void)awakeFromNib
{
    // Initialization code
    inverted = NO;
    
    [self setupAppearanceSettings];
    [self setupGestureRecognizers];
    [self setupSwipeButtons];
    
    if (!inverted) {
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        inverted = YES;
    }
}



# pragma mark setup

- (void) setupAppearanceSettings
{
    [self.message setFont:[UIFont itemContentFont]];
    [self.message setTextColor:[UIColor SHFontDarkGray]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
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





# pragma mark configure

- (void) configureWithItemLocalKey:(NSString*)key
{
    [self setItemLocalKey:key];
    
    NSMutableDictionary* item = [LXObjectManager objectWithLocalKey:self.itemLocalKey];
    
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
    
    [self handleMediaViews];
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
    self.addedConstraints = [[NSMutableArray alloc] init];
    
    NSInteger count = 0;
    for (NSMutableDictionary* medium in [[LXObjectManager objectWithLocalKey:self.itemLocalKey] media]) {
        
        if ([medium width] > 0.0 && [medium height] > 0.0) {
            UIImageView* iv = [self imageViewForMedium:medium];
            
            if ([medium hasID]) {
                
                NSString* croppedMediaURL = [medium mediaThumbnailURLWithWidth:[medium widthForHeight:PICTURE_HEIGHT]];
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

- (UIImageView*) imageViewForMedium:(NSMutableDictionary*)medium
{
    UIImageView* iv = [[UIImageView alloc] init];
    
    [iv setContentMode:UIViewContentModeScaleAspectFill];
    [iv setClipsToBounds:YES];
    [iv setTranslatesAutoresizingMaskIntoConstraints:NO];
    [iv setBackgroundColor:[UIColor SHLightGray]];
    [self addActivityIndicatorToView:iv];
    
    [self.contentView addSubview:iv];
    [self.mediaViews addObject:iv];
    
    return iv;
}

- (void) layoutMedia
{
    NSMutableDictionary* item = [LXObjectManager objectWithLocalKey:self.itemLocalKey];
    
    if ([self.mediaViews count] == 1) {
        UIImageView* iv = [self.mediaViews firstObject];
        NSMutableDictionary* medium = [[item media] firstObject];
        
        if ([item hasMessage]) {
            //fill right 1/3 with the image.
            //right align the message label with the image label
            
            NSArray* verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-10-[imageView(==%i)]-(>=10)-|", PICTURE_HEIGHT] options:0 metrics:nil views:@{@"imageView":iv}];
            NSArray* horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[imageView]-10-|"] options:0 metrics:nil views:@{@"imageView":iv}];
            NSLayoutConstraint * proptionConstraint =
            [NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeHeight multiplier:[medium mediaSizeRatio] constant:0];
            
            [self.contentView addConstraints:horizontalConstraints];
            [self.contentView addConstraints:verticalConstraints];
            [self.contentView addConstraint:proptionConstraint];
            
            [self.addedConstraints addObjectsFromArray:horizontalConstraints];
            [self.addedConstraints addObjectsFromArray:verticalConstraints];
            [self.addedConstraints addObject:proptionConstraint];
            
        } else {
            
            //fill width of cell, match left and right with the message label
            NSArray* verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-10-[imageView(==%i)]-(>=10)-|", PICTURE_HEIGHT] options:0 metrics:nil views:@{@"imageView":iv}];
            NSArray* horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[imageView]-10-|"] options:0 metrics:nil views:@{@"imageView":iv}];
            NSLayoutConstraint * proptionConstraint =
            [NSLayoutConstraint constraintWithItem:iv attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:iv attribute:NSLayoutAttributeHeight multiplier:[medium mediaSizeRatio] constant:0];
            
            [self.contentView addConstraints:horizontalConstraints];
            [self.contentView addConstraints:verticalConstraints];
            [self.contentView addConstraint:proptionConstraint];
            
            [self.addedConstraints addObjectsFromArray:horizontalConstraints];
            [self.addedConstraints addObjectsFromArray:verticalConstraints];
            [self.addedConstraints addObject:proptionConstraint];
        }
    }
}

- (void) addActivityIndicatorToView:(UIView*)view
{
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.alpha = 1.0;
    [view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    [activityIndicator setTag:1];
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

@end
