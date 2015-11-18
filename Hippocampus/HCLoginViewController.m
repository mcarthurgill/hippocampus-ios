//
//  HCLoginViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCLoginViewController.h"
#import "LXAppDelegate.h"
#import "LXTokenViewController.h"

@interface HCLoginViewController ()

@end

@implementation HCLoginViewController

@synthesize titleLabel;
@synthesize secondaryLabel;

@synthesize whyButton;

@synthesize numberTextField;
@synthesize loginButton;
@synthesize countryCodeTextField;

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
    
    [self.loginButton.layer setCornerRadius:4.0f];
    [self.loginButton setClipsToBounds:YES];
    
    [self enableDisableNextButton];
    
    [self setupAppearance];
}

- (void) setupAppearance
{
    [self.titleLabel setFont:[UIFont titleMediumFontWithSize:18.0f]];
    [self.secondaryLabel setFont:[UIFont secondaryFontWithSize:16.0f]];
    [self.secondaryLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [self.countryCodeTextField setFont:[UIFont titleFontWithSize:16.0f]];
    [self.numberTextField setFont:[UIFont titleFontWithSize:16.0f]];
    
    [[self.loginButton titleLabel] setFont:[UIFont titleFontWithSize:16.0f]];
    
    [[self.whyButton titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
    [[self.whyButton titleLabel] setTextColor:[UIColor SHColorBlue]];
    [self.whyButton setTintColor:[UIColor SHColorBlue]];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.numberTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



# pragma mark actions

- (IBAction)loginAction:(id)sender
{
    [sender resignFirstResponder];
    
    [self showHUDWithMessage:@"Working"];
    
    [LXSession loginUser:self.numberTextField.text
          callingCode:[[[self.countryCodeTextField text] componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""]
              success:^(id responseObject){
                  [self hideHUD];
                  NSLog(@"response: %@", responseObject);
                  if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"]) {
                      LXTokenViewController* vc = [[UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"tokenController"];
                      [vc setPhoneNumber:[responseObject objectForKey:@"phone"]];
                      [self.navigationController pushViewController:vc animated:YES];
                  } else {
                      [self showAlertViewWithTitle:@"Uh-oh" message:@"Login failed for some reason."];
                  }
              }
              failure:^(NSError *error){
                  [self hideHUD];
                  [self showAlertViewWithTitle:@"Uh-oh" message:@"Login failed for some reason."];
                  NSLog(@"ERROR: %@", [error localizedDescription]);
              }
     ];
}

- (IBAction) whyMobileAction:(id)sender
{
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Why Your Mobile #" message:@"We need your mobile number for two reasons: 1) to identify your notes as yours; and 2) so you can text notes to Hippocampus." delegate:self cancelButtonTitle:@"Got It." otherButtonTitles:nil];
    [av show];
}

- (IBAction)countryCodeValueChanged:(id)sender
{
    [self enableDisableNextButton];
}

- (IBAction)numberValueChanged:(id)sender
{
    [self enableDisableNextButton];
}

- (void) enableDisableNextButton
{
    if ([self canAdvance]) {
        [self.loginButton setBackgroundColor:[UIColor SHColorBlue]];
        [self.loginButton setEnabled:YES];
    } else {
        [self.loginButton setBackgroundColor:[UIColor SHLightGray]];
        [self.loginButton setEnabled:NO];
    }
}

- (BOOL) canAdvance
{
    return [self.countryCodeTextField text] && [[self.countryCodeTextField text] length] > 1 && [self.numberTextField text] && [[self.numberTextField text] length] > 6;
}

- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [av show];
}



# pragma mark text field delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self loginAction:nil];
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField tag] == 10) {
        NSString* newString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
        NSString *numberString = [[newString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        [textField setText:[NSString stringWithFormat:@"+%@", numberString]];
        [self enableDisableNextButton];
        return NO;
    } else if ([textField  tag] == 11) {
        [textField setText:[[textField text] stringByReplacingCharactersInRange:range withString:string]];
        [self enableDisableNextButton];
        return NO;
    }
    return YES;
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

- (void) hideHUD
{
    [hud hide:YES];
}


@end
