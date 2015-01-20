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


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    [self showHUDWithMessage:@"Working"];
    
    [HCUser tokenVerify:self.tokenInput.text
              phone:self.phoneNumber
              success:^(id responseObject){
                  //[self dismissViewControllerAnimated:YES completion:nil];
                  [self hideHUD];
                  if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"]) {
                      [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Main"];
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
