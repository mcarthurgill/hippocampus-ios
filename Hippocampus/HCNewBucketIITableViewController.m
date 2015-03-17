//
//  HCNewBucketIITableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/9/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCNewBucketIITableViewController.h"
#import "HCItemTableViewController.h"
#import "HCItemPageViewController.h"

@interface HCNewBucketIITableViewController ()

@end

@implementation HCNewBucketIITableViewController

@synthesize delegate;
@synthesize saveButton;
@synthesize firstName;
@synthesize typeOptions;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.typeOptions = @[@"Other", @"Person", @"Event", @"Place"];
    
    [self.firstName becomeFirstResponder];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.typePicker selectRow:1 inComponent:0 animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (IBAction)saveAction:(id)sender
{
    NSLog(@"save!");
    
    if (self.firstName.text && [self.firstName.text length] > 0) {
        
        [self.firstName resignFirstResponder];
        [self showHUDWithMessage:@"Creating Thread"];
        
        [[LXServer shared] createBucketWithFirstName:self.firstName.text andBucketType:[self.typeOptions objectAtIndex:[self.typePicker selectedRowInComponent:0]]
                                             success:^(id responseObject) {
                                                [self hideHUD];
                                                NSDictionary* bucket = responseObject;
                                                [self.delegate addToStack:bucket];
                                                [self.navigationController popToViewController:[[(HCItemTableViewController*)self.delegate pageControllerDelegate] parentViewController] animated:YES];
                                            }failure:^(NSError* error) {
                                                [self hideHUD];
                                                UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"There was an error creating the thread." delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
                                                [av show];
                                            }];
    } else {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"You must enter a Thread name!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [av show];
    }
}


# pragma mark text field delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    
    [self saveAction:nil];
    [textField resignFirstResponder];
    return YES;
}


# pragma mark picker view delegate data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.typeOptions count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.typeOptions objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
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
