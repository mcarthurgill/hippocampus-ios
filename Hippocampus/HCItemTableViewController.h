//
//  HCItemTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCItemPageViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface HCItemTableViewController : UITableViewController <UITextViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
    BOOL unsavedChanges;
    BOOL savingChanges;
    
    MBProgressHUD* hud;
}

@property (strong, nonatomic) HCItemPageViewController* pageControllerDelegate;

@property (strong, nonatomic) NSMutableDictionary* item;
@property (strong, nonatomic) NSMutableDictionary* originalItem;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* actions;

@property (strong, nonatomic) NSMutableDictionary* bucketToRemove;
@property (strong, nonatomic) NSMutableDictionary* mediaDictionary;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) UITextView* messageTextView;

@property (strong, nonatomic) MPMoviePlayerViewController *moviePlayerController;

- (void) saveReminder:(NSString*)reminder withType:(NSString*)type;
- (void) saveUpdatedMessage:(NSString *)updatedMessage;
- (void) addToStack:(id)stackID;

- (void) saveAction:(id)sender;

@end
