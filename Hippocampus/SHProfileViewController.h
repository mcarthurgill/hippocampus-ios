//
//  SHProfileViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/22/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableDictionary* sectionRows;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property (strong, nonatomic) UIImageView* profileImageViewFromCell;
@property (strong, nonatomic) UIButton* emailLabelFromCell;

- (void) action:(NSString*)action;
- (IBAction)rightBarButtonAction:(id)sender;

@end
