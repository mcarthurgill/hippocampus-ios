//
//  HCSetupViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCSetupViewController : UIViewController
{
    BOOL permission;
    BOOL completed; 
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImage *screenshot;
@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UITextField *setupTextField;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIView *blackView;

- (IBAction)dismissAction:(id)sender;
- (IBAction)submitAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@end
