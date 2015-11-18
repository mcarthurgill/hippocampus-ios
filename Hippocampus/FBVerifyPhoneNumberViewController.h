//
//  FBVerifyPhoneNumberViewController.h
//  Flipbook
//
//  Created by Will Schreiber on 8/12/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface FBVerifyPhoneNumberViewController : UIViewController <MFMessageComposeViewControllerDelegate, NSFileManagerDelegate>
{
    MBProgressHUD* hud;
    MBProgressHUD* verifyingHud;
}

@property (strong, nonatomic) id delegate;
@property (nonatomic) UIBackgroundTaskIdentifier bgt;

@property (strong, nonatomic) IBOutlet UIImageView *screenshotImage;
@property (strong, nonatomic) IBOutlet UILabel *verifyLabel;
@property (strong, nonatomic) IBOutlet UILabel *verifyDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *sendTextButton;
@property (strong, nonatomic) IBOutlet UIButton *verifyNowButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property (strong, nonatomic) MFMessageComposeViewController *messageController;

- (IBAction)sendTextAction:(id)sender;
- (IBAction)verifyNowAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
