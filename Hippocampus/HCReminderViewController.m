//
//  HCReminderViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/11/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCReminderViewController.h"
#import "HCItemTableViewController.h"

@interface HCReminderViewController ()

@end

@implementation HCReminderViewController

@synthesize delegate;
@synthesize item;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize datePicker;

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
    if (self.item.reminder) {
        [self.datePicker setDate:self.item.reminder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark actions

- (IBAction)saveAction:(id)sender
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZ"];
    NSString* newDate = [dateFormat stringFromDate:self.datePicker.date];
    NSLog(@"Reminder Date: %@", newDate);
    [self.item setReminderDate:newDate];
    [self dismissViewControllerAnimated:NO completion:^(void){
        [(HCItemTableViewController*)self.delegate saveReminder:newDate];
    }];
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}
@end
