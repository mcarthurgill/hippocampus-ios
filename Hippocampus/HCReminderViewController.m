//
//  HCReminderViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/11/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCReminderViewController.h"
#import "HCItemTableViewController.h"
#import "UIPickerView+CustomPicker.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface HCReminderViewController ()

@end

@implementation HCReminderViewController

@synthesize delegate;
@synthesize item;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize dayPicker;
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
    
    self.typeOptions = @[@"daily", @"weekly", @"monthly", @"yearly", @"once"];
    
    if ([self.item hasReminder]) {
        //[self.datePicker setDate:[NSDate timeWithString:[self.item reminderDate]]];
    }
    if ([self.item hasItemType]) {
        [self.typePicker selectRow:[self indexOfType:[self.item itemType]] inComponent:0 animated:NO];
    } else {
        [self.typePicker selectRow:[self indexOfType:@"once"] inComponent:0 animated:NO];
    }
    
    [self refreshDayPicker];
}

- (void) refreshDayPicker
{
    [self.dayPicker reloadAllComponents];
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
    NSString* newDate = nil;//[dateFormat stringFromDate:self.datePicker.date];
    NSLog(@"Reminder Date: %@", newDate);
    [self.item setObject:newDate forKey:@"reminder_date"];
    [self dismissViewControllerAnimated:NO completion:^(void){
        [(HCItemTableViewController*)self.delegate saveReminder:newDate withType:[self typeSelected]];
    }];
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}



# pragma mark picker view delegate data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    if ([pickerView isTypePicker]) {
        return 1;
    } else {
        if ([self onceMode]) {
            return 3;
        } else if ([self yearlyMode]) {
            return 3;
        } else if ([self monthlyMode]) {
            return 3;
        } else if ([self weeklyMode]) {
            return 2;
        } else if ([self dailyMode]) {
            return 1;
        }
    }
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([pickerView isTypePicker]) {
        return [self.typeOptions count];
    } else {
        if ([self onceMode]) {
            if (component == 0) {
                return 12;
            } else if (component == 1) {
                return 31;
            } else if (component == 2) {
                return 800;
            }
        } else if ([self yearlyMode]) {
            if (component == 0) {
                return 1;
            } else if (component == 1) {
                return 12;
            } else if (component == 2) {
                return 31;
            }
        } else if ([self monthlyMode]) {
            if (component == 0) {
                return 1;
            } else if (component == 1) {
                return 31;
            } else if (component == 2) {
                return 11;
            }
        } else if ([self weeklyMode]) {
            if (component == 0) {
                return 1;
            } else if (component == 1) {
                return 7;
            }
        } else if ([self dailyMode]) {
            return 1;
        }
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([pickerView isTypePicker]) {
        return [self.typeOptions objectAtIndex:row];
    } else {
        if ([self onceMode]) {
            if (component == 0) {
                return [[NSArray months] objectAtIndex:row];
            } else if (component == 1) {
                return [NSString stringWithFormat:@"%i", row+1];
            } else if (component == 2) {
                return [NSString stringWithFormat:@"%i", [NSDate currentYearInteger]+row];
            }
        } else if ([self yearlyMode]) {
            if (component == 0) {
                return @"every";
            } else if (component == 1) {
                return [[NSArray months] objectAtIndex:row];
            } else if (component == 2) {
                return [NSString stringWithFormat:@"%i", row+1];
            }
        } else if ([self monthlyMode]) {
            if (component == 0) {
                return @"the";
            } else if (component == 1) {
                return [NSString stringWithFormat:@"%i", row+1];
            } else if (component == 2) {
                return @"of each month";
            }
        } else if ([self weeklyMode]) {
            if (component == 0) {
                return @"every";
            } else if (component == 1) {
                return [[NSArray daysOfWeek] objectAtIndex:row];
            }
        } else if ([self dailyMode]) {
            return @"every day";
        }
    }
    return 0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    float screenWidth = self.view.frame.size.width;
    float smallWidth = screenWidth/7.0f;
    
    if ([pickerView isTypePicker]) {
        return screenWidth;
    } else {
        if ([self onceMode]) {
            if (component == 0) {
                return (screenWidth-smallWidth)/2.0f;
            } else if (component == 1) {
                return smallWidth;
            } else if (component == 2) {
                return (screenWidth-smallWidth)/2.0f;
            }
        } else if ([self yearlyMode]) {
            if (component == 0) {
                return 1;
            } else if (component == 1) {
                return 12;
            } else if (component == 2) {
                return 31;
            }
        } else if ([self monthlyMode]) {
            if (component == 0) {
                return 1;
            } else if (component == 1) {
                return 31;
            } else if (component == 2) {
                return 11;
            }
        } else if ([self weeklyMode]) {
            if (component == 0) {
                return 1;
            } else if (component == 1) {
                return 7;
            }
        } else if ([self dailyMode]) {
            return 1;
        }
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([pickerView isTypePicker]) {
        NSLog(@"TYPE ROW SELECTED!");
        [self refreshDayPicker];
    } else {
        
    }
}



# pragma mark helper methods

- (BOOL) onceMode
{
    return [[self typeSelected] isEqualToString:@"once"];
}

- (BOOL) yearlyMode
{
    return [[self typeSelected] isEqualToString:@"yearly"];
}

- (BOOL) monthlyMode
{
    return [[self typeSelected] isEqualToString:@"monthly"];
}

- (BOOL) weeklyMode
{
    return [[self typeSelected] isEqualToString:@"weekly"];
}

- (BOOL) dailyMode
{
    return [[self typeSelected] isEqualToString:@"daily"];
}

- (NSString*) typeSelected
{
    return [self.typeOptions objectAtIndex:[self.typePicker selectedRowInComponent:0]];
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
