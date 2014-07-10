//
//  HCLoginViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCLoginViewController.h"
#import "LXAppDelegate.h"

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
    
    [self.numberTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark actions

- (IBAction)loginAction:(id)sender
{
    [HCUser loginUser:self.numberTextField.text
              success:^(id responseObject){
                  //[self dismissViewControllerAnimated:YES completion:nil];
                  [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Main"];
              }
              failure:^(NSError *error){
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

@end
