//
//  HCEditItemViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 7/17/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCEditItemViewController.h"
#import "HCItemTableViewController.h"

@interface HCEditItemViewController ()

@end

@implementation HCEditItemViewController

@synthesize delegate; 
@synthesize item;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize editTextArea;

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
    [self setBorder];
    [editTextArea setText:[self.item objectForKey:@"message"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark setup

- (void) setBorder {
    editTextArea.layer.borderWidth = 0.5f;
    editTextArea.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}


#pragma mark actions

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)saveAction:(id)sender {
    NSString *updatedText = [NSString stringWithFormat:@"%@", editTextArea.text];
    [self.item setObject:updatedText forKey:@"message"];
    [self dismissViewControllerAnimated:NO completion:^(void){
        [(HCItemTableViewController*)self.delegate saveUpdatedMessage:updatedText];
    }];
}
@end
