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
#import "HCPopUpViewController.h"

@interface HCNewBucketIITableViewController ()

@end

@implementation HCNewBucketIITableViewController

@synthesize delegate;
@synthesize saveButton;
@synthesize firstName;
@synthesize typeOptions;
@synthesize descriptionLabel;

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
    
    self.typeOptions = [[LXSession thisSession] groups];
    [self.typeOptions insertObject:@{@"group_name":@"Ungrouped",@"id":@"0"} atIndex:0];
    
    if ([self.typeOptions count] > 1) {
        [self.typePicker setHidden:YES];
        [self.descriptionLabel setHidden:YES];
    } else {
        [self.typePicker setHidden:YES];
        [self.descriptionLabel setHidden:YES];
    }
    
    [self.firstName becomeFirstResponder];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.typePicker selectRow:1 inComponent:0 animated:NO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[LXSetup theSetup] visitedThisScreen:self]) {
        //NSLog(@"already visited new bucket view controller");
    } else {
        //NSLog(@"have not visited new bucket view controller");
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Messages" bundle:[NSBundle mainBundle]];
        HCPopUpViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"popUpViewController"];
        [vc setImageForScreenshotImageView:[[LXSetup theSetup] takeScreenshot]];
        [vc setImageForMainImageView:[UIImage imageNamed:@"new-collection-screen.jpg"]];
        [vc setMainLabelText:@"Name your bucket. Buckets contain thoughts."];
        [self.navigationController presentViewController:vc animated:NO completion:nil];
    }
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
        [self showHUDWithMessage:@"Creating Bucket"];
        
        [[LXServer shared] createBucketWithFirstName:self.firstName.text andGroupID:[[self.typeOptions objectAtIndex:[self.typePicker selectedRowInComponent:0]] ID]
                                             success:^(id responseObject) {
                                                [self hideHUD];
                                                NSDictionary* bucket = responseObject;
                                                [self.delegate addToStack:bucket];
                                                 if ([self.delegate respondsToSelector:@selector(pageControllerDelegate)]) {
                                                     [self.navigationController popToViewController:[[(HCItemTableViewController*)self.delegate pageControllerDelegate] parentViewController] animated:YES];
                                                 } else {
                                                     [self.navigationController popToViewController:self.delegate animated:YES];
                                                 }
                                            }failure:^(NSError* error) {
                                                [self hideHUD];
                                                UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"There was an error creating the bucket." delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
                                                [av show];
                                            }];
    } else {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"You must enter a bucket name!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
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
    return [[self.typeOptions objectAtIndex:row] groupName];
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
