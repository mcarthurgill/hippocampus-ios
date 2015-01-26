//
//  HCReminderViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/11/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCReminderViewController.h"
#import "HCItemTableViewController.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface HCReminderViewController ()

@end

@implementation HCReminderViewController

@synthesize delegate;
@synthesize item;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize datePicker;
@synthesize typePicker;

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
    
    self.typeOptions = @[@"once", @"yearly", @"monthly", @"weekly", @"daily"];
    
    if (NULL_TO_NIL([self.item objectForKey:@"reminder_date"])) {
        [self.datePicker setDate:[NSDate timeWithString:[self.item objectForKey:@"reminder_date"]]];
    }
    if (NULL_TO_NIL([self.item objectForKey:@"item_type"])) {
        [self.typePicker selectRow:[self indexOfType:[self.item objectForKey:@"item_type"]] inComponent:0 animated:NO];
    }
}

- (NSUInteger) indexOfType:(NSString*)t
{
    int i = 0;
    for (NSString* temp in self.typeOptions) {
        if ([temp isEqualToString:t]) {
            return i;
        }
        ++i;
    }
    return 0;
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
    [self.item setObject:newDate forKey:@"reminder_date"];
    [self dismissViewControllerAnimated:NO completion:^(void){
        [(HCItemTableViewController*)self.delegate saveReminder:newDate withType:[self.typeOptions objectAtIndex:[self.typePicker selectedRowInComponent:0]]];
    }];
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
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
