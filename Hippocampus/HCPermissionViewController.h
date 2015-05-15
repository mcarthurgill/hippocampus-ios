//
//  HCPermissionViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HCPermissionsDelegate <NSObject>
-(void)permissionsDelegate;
-(void)permissionsDelegate:(NSString*)type;
@end

@interface HCPermissionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *screenshotImageView;
@property (weak, nonatomic) IBOutlet UIView *tintedView;
@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;
@property (weak, nonatomic) IBOutlet UIButton *grantPermissionButton;
@property (weak, nonatomic) IBOutlet UIButton *laterButton;

- (IBAction)grantPermissionAction:(id)sender;
- (IBAction)backgroundButtonAction:(id)sender;

//the properties below are the ones you set for customization
@property (strong, nonatomic) UIImage *imageForMainImageView;
@property (strong, nonatomic) UIImage *imageForScreenshotImageView;
@property (strong, nonatomic) NSString *mainLabelText;
@property (strong, nonatomic) NSString *permissionType;
@property (strong, nonatomic) NSString *buttonText;
@property (strong, nonatomic) id delegate;

@end
