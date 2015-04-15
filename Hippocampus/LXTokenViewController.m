//
//  LXTokenViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 1/20/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXTokenViewController.h"
#import "LXAppDelegate.h"

@interface LXTokenViewController ()

@end

@implementation LXTokenViewController

@synthesize phoneNumber;
@synthesize tokenInput;
@synthesize explanationLabel;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.explanationLabel setText:[NSString stringWithFormat:@"We just texted a code to %@", phoneNumber]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tokenInput becomeFirstResponder];
}


- (IBAction)goAction:(id)sender
{
    [sender resignFirstResponder];
    
    [self showHUDWithMessage:@"Working"];
    
    [HCUser tokenVerify:self.tokenInput.text
              phone:self.phoneNumber
              success:^(id responseObject){
                  //[self dismissViewControllerAnimated:YES completion:nil];
                  [self hideHUD];
                  if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"]) {
                      [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Messages"];
                  } else {
                      [self showAlertViewWithTitle:@"Uh-oh" message:@"Token could not be verified. Try again!"];
                  }
              }
              failure:^(NSError *error){
                  [self hideHUD];
                  [self showAlertViewWithTitle:@"Uh-oh" message:@"Token verification failed for some reason."];
                  NSLog(@"ERROR: %@", [error localizedDescription]);
              }
     ];
}

- (IBAction)backAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (void) showAlertViewWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [av show];
}



# pragma mark text field delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self goAction:nil];
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString* newString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
    [textField setText:newString];
    if ([newString length] == 4) {
        [self goAction:nil];
    }
    return NO;
}



# pragma mark hud delegate

- (void) showHUDWithMessage:(NSString*) message
{
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = message;
}

- (void) hideHUD
{
    [hud hide:YES];
}


@end
