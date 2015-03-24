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

@synthesize numberTextField;
@synthesize loginButton;

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
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        [self.numberTextField becomeFirstResponder];
    });
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
    
    [HCUser loginUser:self.numberTextField.text
              success:^(id responseObject){
                  //[self dismissViewControllerAnimated:YES completion:nil];
                  [self hideHUD];
                  //[(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Main"];
                  if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"]) {
                      LXTokenViewController* vc = [[UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"tokenController"];
                      [vc setPhoneNumber:self.numberTextField.text];
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
