//
//  FBVerifyPhoneNumberViewController.m
//  Flipbook
//
//  Created by Will Schreiber on 8/12/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "FBVerifyPhoneNumberViewController.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "NSString+SHAEncryption.h"
#import "LXAppDelegate.h"

@interface FBVerifyPhoneNumberViewController ()

@end

@implementation FBVerifyPhoneNumberViewController

@synthesize delegate;

@synthesize screenshotImage;
@synthesize verifyLabel;
@synthesize verifyDescriptionLabel;
@synthesize sendTextButton;
@synthesize verifyNowButton;
@synthesize cancelButton;

@synthesize messageController;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self.verifyNowButton.layer setCornerRadius:4.0f];
    [self.verifyNowButton setClipsToBounds:YES];
    
    [self.verifyDescriptionLabel setTextColor:[UIColor blackColor]];
    
    self.screenshotImage.layer.shadowColor = [UIColor grayColor].CGColor;
    self.screenshotImage.layer.shadowOffset = CGSizeMake(0, 1);
    self.screenshotImage.layer.shadowOpacity = 1;
    self.screenshotImage.layer.shadowRadius = 1.0;
    self.screenshotImage.clipsToBounds = NO;
    
    [self.verifyDescriptionLabel setFont:[UIFont secondaryFontWithSize:18.0f]];
    [self.verifyDescriptionLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [[self.sendTextButton titleLabel] setFont:[UIFont titleFontWithSize:12.0f]];
    [[self.sendTextButton titleLabel] setTextColor:[UIColor SHColorBlue]];
    [self.sendTextButton setTintColor:[UIColor SHColorBlue]];
    
    [[self.verifyNowButton titleLabel] setFont:[UIFont titleFontWithSize:16.0f]];
    [self.verifyNowButton setBackgroundColor:[UIColor SHColorBlue]];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self hideHUD];

    if (![self canDevicePlaceAPhoneCall]) {
        //tell server to send phone a text
        [self sendTextAction:nil];
        
        NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray: self.navigationController.viewControllers];
        [allViewControllers removeObjectIdenticalTo:self];
        self.navigationController.viewControllers = allViewControllers;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupView
{
    if ([MFMessageComposeViewController canSendText]) {
        [self.verifyNowButton setHidden:NO];
    } else {
        [self.verifyNowButton setHidden:YES];
    }
}



# pragma mark actions


- (IBAction)sendTextAction:(id)sender
{
    //tell server to send phone a text
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]];
    
    NSString* identifier = @"verifyNumberViewController";
    
    id vc = [storyboard instantiateViewControllerWithIdentifier:identifier];
    [self.navigationController pushViewController:vc animated:NO];
}

- (IBAction)verifyNowAction:(id)sender
{
    if ([MFMessageComposeViewController canSendText]) {
        
        NSString* token = [[NSString random:16] shaEncrypted];
        
        NSString *message = [NSString stringWithFormat:@"My code: (%@). Verify me!", [NSString stringWithFormat:@"%@==", token]];
        
        [[LXSession thisSession] addVerifyingToken:token];
        
        self.messageController = [[MFMessageComposeViewController alloc] init];
        self.messageController.messageComposeDelegate = self;
        [self.messageController setRecipients:@[@"+16157249333"]];
        [self.messageController setBody:message];
        // Present message view controller on screen
        
        [self showHUDWithMessage:@"Getting token..."];
        
        [self presentViewController:self.messageController animated:YES completion:nil];
        
    }
}


- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void){
    }];
}



# pragma mark message compose view controller delegate

- (void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    if (result == MessageComposeResultSent) {
        //fake completion until we can go back to the server to check...
        [self.screenshotImage setHidden:YES];
        [self.verifyLabel setHidden:YES];
        [self.verifyDescriptionLabel setHidden:YES];
        [self.sendTextButton setHidden:YES];
        [self.verifyNowButton setHidden:YES];
        [self showVerifyingHUDWithMessage:@"Verifying..."];
        
        [controller dismissViewControllerAnimated:NO completion:^(void){
        }];
        
        _bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
        }];
        [self performSelector:@selector(checkForLogin) withObject:nil afterDelay:1.0];
        
    } else if (result == MessageComposeResultFailed) {
        [controller dismissViewControllerAnimated:NO completion:nil];
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Darn!" message:@"There was an error sending the verification text. Try again." delegate:self cancelButtonTitle:@"Alright." otherButtonTitles:nil];
        [av show];
    } else {
        [controller dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) checkForLogin
{
    [LXSession loginWithToken:[[[LXSession thisSession] verifyingTokens] lastObject]
                success:^(id responseObject){
                    //[self dismissViewControllerAnimated:YES completion:nil];
                    [self hideHUD];
                    if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"]) {
                        [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Seahorse"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"presentTutorial" object:nil];
                        [[UIApplication sharedApplication] endBackgroundTask:_bgt];
                    } else {
                        [self performSelector:@selector(checkForLogin) withObject:nil afterDelay:1.0];
                    }
                }
                failure:^(NSError *error){
                    [self performSelector:@selector(checkForLogin) withObject:nil afterDelay:4.0];
                    NSLog(@"ERROR: %@", [error localizedDescription]);
                }
     ];
}


# pragma mark helpers

-(BOOL) canDevicePlaceAPhoneCall
{
    // Check if the device can place a phone call
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
        // Device supports phone calls, lets confirm it can place one right now
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        NSString *mnc = [carrier mobileNetworkCode];
        return !(([mnc length] == 0) || ([mnc isEqualToString:@"65535"]));
    }
    return NO;
}



# pragma mark hud delegate

- (void) showHUDWithMessage:(NSString*) message
{
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.labelText = message;
    hud.color = [[UIColor SHGreen] colorWithAlphaComponent:0.8f];
    [hud show:YES];
}

- (void) showVerifyingHUDWithMessage:(NSString*) message
{
    verifyingHud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:verifyingHud];
    verifyingHud.labelText = message;
    verifyingHud.color = [[UIColor SHGreen] colorWithAlphaComponent:0.8f];
    [verifyingHud show:YES];
}

- (void) hideHUD
{
    if (hud) {
        [hud hide:YES];
    }
}

- (void) hideVerifyingHUD
{
    if (verifyingHud) {
        [verifyingHud hide:YES];
    }
}

@end
