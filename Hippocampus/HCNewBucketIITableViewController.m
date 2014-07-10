//
//  HCNewBucketIITableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/9/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCNewBucketIITableViewController.h"

@interface HCNewBucketIITableViewController ()

@end

@implementation HCNewBucketIITableViewController

@synthesize bucket;
@synthesize saveButton;
@synthesize firstName;
@synthesize lastName;

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
    
    if (self.bucket && ![self.bucket isPersonType]) {
        [self.firstName setPlaceholder:@"Name of Stack"];
        [self.lastName setHidden:YES];
        [self.firstName setReturnKeyType:UIReturnKeyGo];
    }
    
    [self.firstName becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (IBAction)saveAction:(id)sender
{
    [self.bucket setFirstName:self.firstName.text];
    [self.bucket setLastName:self.lastName.text];
    [self.bucket saveWithSuccess:^(id responseBlock) {
                            [self dismissViewControllerAnimated:YES completion:nil];
                            NSLog(@"SUCCESS! %@", responseBlock);
                         }
                         failure:^(NSError *error) {
                             NSLog(@"Error! %@", [error localizedDescription]);
                         }
     ];
}


# pragma mark text field delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (self.bucket && [self.bucket isPersonType]) {
        NSUInteger tag = textField.tag;
        UITextField* nextField = (UITextField*)[textField.superview viewWithTag:(tag+1)];
        if (nextField) {
            [nextField becomeFirstResponder];
            return YES;
        }
    }
    [self saveAction:nil];
    [textField resignFirstResponder];
    return YES;
}

@end
