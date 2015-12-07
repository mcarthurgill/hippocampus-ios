//
//  SHMessagesViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/18/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHMessagesViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    NSInteger page;
}

@property (strong, nonatomic) NSString* localKey;
@property (nonatomic) BOOL shouldReload;
@property (nonatomic) BOOL currentlyCellSwiping;

@property (strong, nonatomic) NSMutableDictionary* blankItem;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *inputToolbar;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomConstraint;
@property (strong, nonatomic) IBOutlet UIView *placeholderLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *inputControlToolbarHeightConstraint;
@property (strong, nonatomic) IBOutlet UIView *inputControlToolbar;
@property (strong, nonatomic) IBOutlet UIButton *rightButton;
@property (strong, nonatomic) IBOutlet UIButton *leftButton;
@property (strong, nonatomic) IBOutlet UIButton *leftPlaceholderButton;
@property (strong, nonatomic) IBOutlet UIButton *rightPlaceholderButton;

- (void) tryToReload;

- (IBAction)rightButtonAction:(id)sender;
- (IBAction)leftButtonAction:(id)sender;

- (IBAction)leftPlaceholderAction:(id)sender;
- (IBAction)rightPlaceholderAction:(id)sender;

@end
