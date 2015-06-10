//
//  HCItemTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCItemTableViewCell.h"
#import "LXAppDelegate.h"
#import "HCBucketsTableViewController.h"
#import "HCBucketViewController.h"
#import "HCReminderViewController.h"

#define IMAGE_FADE_IN_TIME 0.4f
#define PICTURE_HEIGHT 280
#define PICTURE_MARGIN_TOP 8

@implementation HCItemTableViewCell

@synthesize item;

@synthesize mediaView;

@synthesize player, playerLayer, asset, playerItem;


- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) configureWithItem:(NSDictionary*) itm
{
    self.item = [[NSDictionary alloc] initWithDictionary:itm];
    
    for (UIGestureRecognizer* gr in [self gestureRecognizers]) {
        if ([gr isMemberOfClass:[UILongPressGestureRecognizer class]]) {
            [self removeGestureRecognizer:gr];
        }
    }
    if ([self.item hasID]) {
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        lpgr.minimumPressDuration = 0.5; //seconds
        lpgr.delegate = self;
        [self addGestureRecognizer:lpgr];
        
        //configure left buttons
        self.rightButtons = @[[MGSwipeButton buttonWithTitle:@"Delete" icon:nil backgroundColor:[UIColor redColor]],
                              [MGSwipeButton buttonWithTitle:@"+" icon:nil backgroundColor:[UIColor blueColor]]];
        self.rightSwipeSettings.transition = MGSwipeTransitionBorder;
        [self setDelegate:self];
    } else {
        self.rightButtons = nil;
    }
    
    UILabel* note = (UILabel*)[self.contentView viewWithTag:1];
    UIFont* font = note.font;
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    
    [note removeFromSuperview];
    
    CGFloat width = self.contentView.frame.size.width - 10 - 25;
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[item truncatedMessage] width:width font:font]+4.0f)];
    
    [note setFont:font];
    [note setText:[item truncatedMessage]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [self.contentView addSubview:note];
    
    UILabel* blueDot = (UILabel*) [self.contentView viewWithTag:4];
    
    if ([item isOutstanding]) { //|| ![item hasID]) {
        //[blueDot setBackgroundColor:([item hasID] ? [UIColor blueColor] : [UIColor orangeColor])];
        [blueDot setBackgroundColor:[UIColor blueColor]];
        [blueDot.layer setCornerRadius:4];
        [blueDot setClipsToBounds:YES];
        [blueDot setHidden:NO];
    } else {
        [blueDot setHidden:YES];
    }
    
    UILabel* timestamp = (UILabel*)[self.contentView viewWithTag:3];
    [timestamp setText:([item hasID] ? [NSString stringWithFormat:@"%@%@", ([item hasBucketsString] ? [NSString stringWithFormat:@"%@ - ", [item bucketsString]] : @""), [self dateToDisplayForItem:item]] : @"will sync with internet")];
    
    int i = 0;
    if ([item croppedMediaURLs]) {
        for (NSString* url in [item croppedMediaURLs]) {
            
            if ([url isImageUrl]) {
                UIImageView* iv = [self.contentView viewWithTag:(200+i)] ? (UIImageView*)[self.contentView viewWithTag:(200+i)] : [[UIImageView alloc] init];
                
                for (UIGestureRecognizer *recognizer in iv.gestureRecognizers) {
                    [iv removeGestureRecognizer:recognizer];
                }
                
                UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressMedia:)];
                [longPress setMinimumPressDuration:0.15f];
                [iv addGestureRecognizer:longPress];
                [iv setUserInteractionEnabled:YES];
                [iv setExclusiveTouch:YES];
                
                [iv setBackgroundColor:[UIColor clearColor]];
                [iv setFrame:CGRectMake(20, note.frame.origin.y+note.frame.size.height+PICTURE_MARGIN_TOP+(PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*i, self.contentView.frame.size.width-40.0f, PICTURE_HEIGHT)];
                [iv setTag:(200+i)];
                ++i;
                
                iv.layer.borderWidth = 0.8f;
                iv.layer.borderColor = [UIColor grayColor].CGColor;
                
                [iv setContentMode:UIViewContentModeScaleAspectFill];
                [iv setClipsToBounds:YES];
                [iv.layer setCornerRadius:8.0f];
                
                UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                activityIndicator.alpha = 1.0;
                [activityIndicator setFrame:CGRectMake(iv.frame.size.width/2, iv.frame.size.height/2, activityIndicator.frame.size.width, activityIndicator.frame.size.height)];
                [iv addSubview:activityIndicator];
                [activityIndicator startAnimating];
                
                if ([item hasID]) {
                    
                    if ([SGImageCache haveImageForURL:url]) {
                        iv.image = [SGImageCache imageForURL:url];
                        [iv setAlpha:1.0f];
                        activityIndicator.alpha = 0.0;
                    } else if (![iv.image isEqual:[SGImageCache imageForURL:url]]) {
                        iv.image = nil;
                        [iv setAlpha:1.0f];
                        [SGImageCache getImageForURL:url].then(^(UIImage* image) {
                            if (image) {
                                float curAlpha = [iv alpha];
                                [iv setAlpha:0.0f];
                                iv.image = image;
                                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void){
                                    [iv setAlpha:curAlpha];
                                    activityIndicator.alpha = 0.0;
                                }];
                            }
                        });
                    }
                    
                } else {
                    if ([NSData dataWithContentsOfFile:url] && ![iv.image isEqual:[UIImage imageWithData:[NSData dataWithContentsOfFile:url]]]) {
                        [iv setAlpha:0.0f];
                        iv.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:url]];
                        [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                            [iv setAlpha:1.0f];
                            activityIndicator.alpha = 0.0;
                        }];
                    }
                }
                
                if (!iv.superview) {
                    [self.contentView addSubview:iv];
                }
            }
        }
    }
    
    UIImageView* alarmClock = (UIImageView*) [self.contentView viewWithTag:32];
    if ([item hasReminder]) {
        [alarmClock setHidden:NO];
    } else {
        [alarmClock setHidden:YES];
    }
    
    while ([self.contentView viewWithTag:(200+i)]) {
        [[self.contentView viewWithTag:(200+i)] removeFromSuperview];
        ++i;
    }
}





# pragma mark cell helpers

+ (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    if (!text || [text length] == 0) {
        return 0.0f;
    }
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, 100000)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    return rect.size.height;
}

- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    return [HCItemTableViewCell heightForText:text width:width font:font];
}

- (NSString*) dateToDisplayForItem:(NSDictionary*)i
{
    if (i && [i hasNextReminderDate]) {
        return [NSString stringWithFormat:@"%@ - %@", [i itemType], [NSDate formattedDateFromString:[i nextReminderDate]]];
    } else {
        return [NSDate timeAgoInWordsFromDatetime:[i createdAt]];
    }
}

+ (CGFloat) heightForCellWithItem:(NSDictionary *)item
{
    int additional = 0;
    if ([item hasMediaURLs]) {
        int numImages = 0;
        for (NSString *url in [item mediaURLs]) {
            if ([url isImageUrl]) {
                numImages++;
            }
        }
        additional = (PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*numImages;
    }
    return [self heightForText:[item truncatedMessage] width:((int)[[UIScreen mainScreen] bounds].size.width-40.0f) font:[UIFont noteDisplay]] + 22.0f + 12.0f + 14.0f + additional + 4.0f;
}





# pragma mark gesture recognizers


-(void) handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIActionSheet* aS = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Add to Bucket", @"Set Nudge", @"Copy", nil];
        [aS showInView:self.superview];
    }
}

- (void) longPressMedia:(UILongPressGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed || gesture.state == UIGestureRecognizerStateEnded) {
        if (self.mediaView) {
            [self.mediaView removeFromSuperview];
            [self setMediaView:nil];
        }
        if (self.player) {
            [self.player pause];
            [self setPlayer:nil];
            [self setAsset:nil];
            [self setPlayerItem:nil];
            [self setPlayerLayer:nil];
        }
        [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelNormal];
    }
    
    else if (!self.mediaView) {
        
        int index = ([[gesture view] tag])%100;
        [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelStatusBar+1];
        // Get main window reference
        UIWindow* mainWindow = (((LXAppDelegate *)[UIApplication sharedApplication].delegate).window);
        
        NSString *url = [[self.item croppedMediaURLs] objectAtIndex:index];
        NSUInteger indexOfVideoUrl = [self.item indexOfMatchingVideoUrl:url];
        
        // Create a full-screen subview
        self.mediaView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height+[[UIApplication sharedApplication] statusBarFrame].size.height)];
        // Set up some properties of the subview
        self.mediaView.backgroundColor = [UIColor blackColor];
        [self.mediaView setContentMode:UIViewContentModeScaleAspectFit];
        
        if (indexOfVideoUrl != -1) {
            //VIDEO
            
            if (!self.player) {
                
                self.asset = [AVAsset assetWithURL:[NSURL URLWithString:[[self.item mediaURLs] objectAtIndex:indexOfVideoUrl]]];
                if (!self.playerItem) {
                    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
                }
                if (!self.player) {
                    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
                    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
                }
                
                if (!self.playerLayer) {
                    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
                    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
                    [self.playerLayer setFrame:self.mediaView.frame];
                    [self.mediaView.layer addSublayer:self.playerLayer];
                }
                [self.player play];
                
            }
            
        } else {
            
            //IMAGE
            if ([self.item hasID]) {
                if ([SGImageCache haveImageForURL:url]) {
                    [self.mediaView setImage:[SGImageCache imageForURL:url]];
                } else if (![self.mediaView.image isEqual:[SGImageCache imageForURL:url]]) {
                    self.mediaView.image = nil;
                    [SGImageCache getImageForURL:url].then(^(UIImage* image) {
                        if (image) {
                            self.mediaView.image = image;
                        }
                    });
                }
            } else {
                if ([NSData dataWithContentsOfFile:url] && ![self.mediaView.image isEqual:[UIImage imageWithData:[NSData dataWithContentsOfFile:url]]]) {
                    self.mediaView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:url]];
                }
            }
            
        }
        
        // Add the subview to the main window
        [mainWindow addSubview:self.mediaView];
    }
}





# pragma mark MGSwipeDelegate

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    //NSLog(@"tapped button at Index: %li", (long)index);
    if (index == 0) {
        //DELETE
        [self alertForDeletion];
    } else if (index == 1) {
        //ADD
        [self addToCollectionAction];
    }
    return YES;
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //DELETE
        [self alertForDeletion];
    } else if (buttonIndex == 1) {
        //ADD TO COLLECTION
        [self addToCollectionAction];
    } else if (buttonIndex == 2) {
        //SET NUDGE
        [self reminderAction];
    } else if (buttonIndex == 3) {
        //COPY
        [self copyAction];
    }
}

- (void) addToCollectionAction
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCBucketsTableViewController* itvc = (HCBucketsTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"bucketsTableViewController"];
    [itvc setMode:@"assign"];
    [itvc setDelegate:self];
    [[[self getParentViewController] navigationController] pushViewController:itvc animated:YES];
}

- (void) reminderAction
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
    HCReminderViewController* itvc = (HCReminderViewController*)[storyboard instantiateViewControllerWithIdentifier:@"reminderViewController"];
    [itvc setItem:[self.item mutableCopy]];
    [itvc setDelegate:self];
    [[self getParentViewController] presentViewController:itvc animated:YES completion:nil];
}

- (void) copyAction
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self.item message];
    if ([self.item croppedMediaURLs] && [[self.item croppedMediaURLs] count] > 0) {
        NSMutableArray* images = [[NSMutableArray alloc] init];
        for (NSString* url in [self.item croppedMediaURLs]) {
            if ([SGImageCache haveImageForURL:url]) {
                [images addObject:[SGImageCache imageForURL:url]];
            }
        }
        [pasteboard setImages:(NSArray*)images];
    }
    [self showHUDWithMessage:@"Copying"];
    [self performSelector:@selector(hideHUD) withObject:nil afterDelay:0.5f];
}

- (void) addToStack:(NSDictionary*)b
{
    [self showHUDWithMessage:[NSString stringWithFormat:@"Adding to the '%@' Bucket", [b objectForKey:@"first_name"]]];
    
    [[LXServer shared] addItem:self.item toBucket:b
                       success:^(id responseObject) {
                           NSMutableDictionary* itemActionCopy = [self.item mutableCopy];
                           [itemActionCopy setObject:[responseObject objectForKey:@"buckets"] forKey:@"buckets"];
                           [itemActionCopy setObject:@"assigned" forKey:@"status"];
                           //[self.allItems replaceObjectAtIndex:[self.allItems indexOfObject:self.itemForAction] withObject:itemActionCopy];
                           [self hideHUD];
                           //[self reloadScreen];
                           [self initiateDelegateCallbackWithAction:@"addToStack" newItem:itemActionCopy];
                       }failure:^(NSError *error){
                           [self hideHUD];
                           //[self reloadScreen];
                       }];
}

- (void) saveReminder:(NSString*)reminder withType:(NSString*)type
{
    NSMutableDictionary* itemActionCopy = [self.item mutableCopy];
    [itemActionCopy setObject:reminder forKey:@"reminder_date"];
    [itemActionCopy setObject:type forKey:@"item_type"];
    [itemActionCopy setObject:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"device_request_timestamp"];
    
    [self showHUDWithMessage:[NSString stringWithFormat:@"Setting Nudge"]];
    
    [[LXServer shared] saveReminderForItem:itemActionCopy
                                   success:^(id responseObject) {
                                       [self hideHUD];
                                       [self initiateDelegateCallbackWithAction:@"setReminder" newItem:itemActionCopy];
                                   }failure:^(NSError *error){
                                       NSLog(@"unsuccessfully updated reminder date");
                                       [self hideHUD];
                                   }];
}

- (void) initiateDelegateCallbackWithAction:(NSString*)action newItem:(NSMutableDictionary*)newI
{
    id view = self;
    while (![view isKindOfClass:[UITableView class]] && [view superview]) {
        //NSLog(@"class of superview: %@", [[[view superview] class] description]);
        view = [view superview];
    }
    if ([[view dataSource] respondsToSelector:@selector(actionTaken:forItem:newItem:)]) {
        [(HCBucketViewController*)[view dataSource] actionTaken:action forItem:self.item newItem:newI];
    }
}




# pragma  mark - AlertView Delegate

- (void) alertForDeletion
{
    NSString *title = @"Sorry";
    NSString *message = @"You cannot delete a thought you did not add!";
    NSString *buttonTitle = @"Okay";
    NSString *cancelTitle = nil;
    
    if (self.item && [self.item belongsToCurrentUser]) {
        title = @"Are you sure?";
        message = @"Do you want to delete this thought?";
        buttonTitle = @"Delete";
        cancelTitle = @"Cancel";
    }
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:cancelTitle
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:buttonTitle];
    [alert show];
}


- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if (self.item && [self.item belongsToCurrentUser]) {
            [self showHUDWithMessage:@"Deleting"];
            [self.item deleteItemWithSuccess:^(id responseObject) {
                [self hideHUD];
                //INITIATE CALLBACK!
                [self initiateDelegateCallbackWithAction:@"delete" newItem:nil];
            } failure:^(NSError* error) {
                [self hideHUD];
            }];
        }
    }
}

- (HCBucketViewController*) getParentViewController
{
    id view = self;
    while (![view isKindOfClass:[UITableView class]] && [view superview]) {
        //NSLog(@"class of superview: %@", [[[view superview] class] description]);
        view = [view superview];
    }
    return (HCBucketViewController*)[view dataSource];
}



# pragma mark media handling

- (void) playerItemDidReachEnd:(NSNotification*)notification
{
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}




# pragma mark hud delegate

- (void) showHUDWithMessage:(NSString*) message
{
    hud = [MBProgressHUD showHUDAddedTo:[self getParentViewController].view animated:YES];
    hud.labelText = message;
}

- (void) hideHUD
{
    [hud hide:YES];
}


@end
