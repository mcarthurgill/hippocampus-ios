//
//  HCBucketViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/3/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCItemTableViewController.h"

@protocol HCSendRequestForUpdatedBuckets <NSObject>
-(void)sendRequestForUpdatedBucket;
@end

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })



@interface HCBucketViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>
{
    BOOL requestMade;
    BOOL shouldContinueRequesting;
    
    CGFloat maxComposeTextViewSize;
    
    MBProgressHUD* hud;
}

@property (strong, nonatomic) NSMutableDictionary* bucket;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *composeView;
@property (weak, nonatomic) IBOutlet UITextView *composeTextView;

@property (strong, nonatomic) UIView *congratsView;

@property (strong, nonatomic) NSString *scrollToPosition;
@property BOOL initializeWithKeyboardUp;
@property int page;

@property (nonatomic,assign) id delegate;

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* allItems;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) NSMutableArray* imageAttachments;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableviewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewTopVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomVerticalSpaceConstraint;

@property (strong, nonatomic) UIImagePickerController *pickerController;
@property (strong, nonatomic) NSMutableDictionary* metadata;
@property (strong, nonatomic) NSMutableDictionary *itemForDeletion;

- (IBAction)addAction:(id)sender;
- (IBAction)uploadImage:(id)sender;
- (IBAction)detailsAction:(id)sender;

- (void) updateItemsArrayWithOriginal:(NSMutableDictionary*)original new:(NSMutableDictionary*)n;
- (void) scrollToNote:(NSMutableDictionary*)original;




@end
