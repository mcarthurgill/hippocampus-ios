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
    // Do any additional setup after loading the view.
    
    //[[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont flipbookActionFontWithSize:16.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    //[self.navigationItem.leftBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont flipbookActionFontWithSize:16.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    //[self.navigationItem.rightBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont flipbookActionFontWithSize:16.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    //[self.navigationController.navigationBar setBarTintColor:[UIColor flipbookPurple]];
    //[self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    //[self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont flipbookDescriptionFontWithSize:24.0f], NSFontAttributeName, [UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    //[self.navigationItem setTitle:@"Verify"];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    //[self.sendTextButton.titleLabel setFont:[UIFont flipbookActionFontWithSize:13.0f]];
    //[self.sendTextButton.titleLabel setTextColor:[UIColor whiteColor]];
    //[self.sendTextButton setBackgroundColor:[UIColor darkGrayColor]];
    
    //[self.verifyNowButton.titleLabel setFont:[UIFont flipbookActionFontWithSize:20.0f]];
    //[self.verifyNowButton.titleLabel setTextColor:[UIColor whiteColor]];
    //[self.verifyNowButton setBackgroundColor:[UIColor blueColor]]; //[self.verifyNowButton setBackgroundColor:[UIColor flipbookPurple]];
    [self.verifyNowButton.layer setCornerRadius:4.0f];
    [self.verifyNowButton setClipsToBounds:YES];
    
    //[self.verifyLabel setFont:[UIFont flipbookDescriptionFontWithSize:28.0f]];
    //[self.verifyLabel setText:@""];
    //[self.verifyLabel setTextColor:[UIColor blackColor]];
    
    //[self.verifyDescriptionLabel setFont:[UIFont flipbookDescriptionFontWithSize:24.0f]];
    [self.verifyDescriptionLabel setTextColor:[UIColor blackColor]];
    
    self.screenshotImage.layer.shadowColor = [UIColor grayColor].CGColor;
    self.screenshotImage.layer.shadowOffset = CGSizeMake(0, 1);
    self.screenshotImage.layer.shadowOpacity = 1;
    self.screenshotImage.layer.shadowRadius = 1.0;
    self.screenshotImage.clipsToBounds = NO;
    
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
        
        [self showHUDWithMessage:nil];
        
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
    [HCUser loginWithToken:[[[LXSession thisSession] verifyingTokens] lastObject]
                success:^(id responseObject){
                    //[self dismissViewControllerAnimated:YES completion:nil];
                    [self hideHUD];
                    if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"]) {
                        [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Messages"];
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
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = message;
    //[hud setColor:[UIColor flipbookRed]];
    //[hud setLabelFont:[UIFont flipbookDescriptionFontWithSize:16.0f]];
}

- (void) showVerifyingHUDWithMessage:(NSString*) message
{
    verifyingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    verifyingHud.labelText = message;
    //[hud setColor:[UIColor flipbookRed]];
    //[hud setLabelFont:[UIFont flipbookDescriptionFontWithSize:16.0f]];
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
