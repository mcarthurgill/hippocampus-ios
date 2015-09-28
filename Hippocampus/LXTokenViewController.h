//
//  LXTokenViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 1/20/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXTokenViewController : UIViewController <UITextFieldDelegate>
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) NSString* phoneNumber;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *explanationLabel;
@property (strong, nonatomic) IBOutlet UITextField *tokenInput;
@property (strong, nonatomic) IBOutlet UIButton *backButton;

- (IBAction)goAction:(id)sender;
- (IBAction)backAction:(id)sender;


@end
