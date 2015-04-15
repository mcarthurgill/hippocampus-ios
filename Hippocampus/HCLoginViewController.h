//
//  HCLoginViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCLoginViewController : UIViewController <UITextFieldDelegate>
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) IBOutlet UITextField *countryCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)loginAction:(id)sender;
- (IBAction)whyMobileAction:(id)sender;

- (IBAction)countryCodeValueChanged:(id)sender;
- (IBAction)numberValueChanged:(id)sender;

@end
