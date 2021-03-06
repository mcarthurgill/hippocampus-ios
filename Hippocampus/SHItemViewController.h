//
//  SHItemViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHAttachmentBoxTableViewCell.h"
@import AVFoundation;

@interface SHItemViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) NSString* localKey;
@property (strong, nonatomic) NSMutableDictionary* mediaInQuestion;
@property (strong, nonatomic) AVPlayer *anAudioStreamer;
@property (strong, nonatomic) NSTimer *audioTimer;
@property (strong, nonatomic) SHAttachmentBoxTableViewCell *audioTableViewCell;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *bottomToolbar;

@property (strong, nonatomic) UILabel* outstandingLabel;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* toolbarOptions;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *trailingSpace;

- (void) reloadScreen;

- (void) longPressWithObject:(NSMutableDictionary*)object type:(NSString*)action;

@end
