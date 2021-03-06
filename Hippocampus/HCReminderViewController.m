//
//  HCReminderViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/11/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCReminderViewController.h"
#import "UIPickerView+CustomPicker.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@interface HCReminderViewController ()

@end

@implementation HCReminderViewController

@synthesize localKey;
@synthesize cancelButton;
@synthesize saveButton;
@synthesize currentlySelectedDate;
@synthesize dayPicker;
@synthesize typeSegmentedControl;
@synthesize subtitleLabel;

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
    
    [self setupSettings];
    
    [self setupNudge];
    [self refreshDayPicker];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) setupSettings
{
    [self.dayPicker setBackgroundColor:[UIColor whiteColor]];
    
    [self.typeSegmentedControl setTitleTextAttributes:@{NSFontAttributeName : [UIFont titleFontWithSize:11.0f]} forState:UIControlStateNormal];
    
    [self.subtitleLabel setFont:[UIFont secondaryFontWithSize:12.0f]];
    [self.subtitleLabel setTextColor:[UIColor SHFontDarkGray]];
}

- (void) setupNudge
{
    self.typeOptions = @[@"once", @"yearly", @"monthly", @"weekly", @"daily"];
    
    if ([[self item] hasReminder]) {
        [self setCurrentlySelectedDate:[NSDate timeWithString:[[self item] reminderDate]]];
    } else {
        [self setCurrentlySelectedDate:[NSDate date]];
    }
    
    if ([[self item] hasItemType]) {
        [self.typeSegmentedControl setSelectedSegmentIndex:([self indexOfType:[[self item] itemType]])];
    } else {
        [self.typeSegmentedControl setSelectedSegmentIndex:0];
    }
}


- (void) refreshAfterSelect
{
    [self setCurrentlySelectedDate:[self createDateFromDayPicker]];
    [self refreshDayPicker];
}

- (void) refreshDayPicker
{
    [self.dayPicker reloadAllComponents];
    [self.dayPicker setNeedsLayout];
    [self setToCurrentlySelectedDay];
}

- (void) setToCurrentlySelectedDay
{
    //NSLog(@"%li %li %li", (long)[self.currentlySelectedDate yearIndex], (long)[self.currentlySelectedDate monthIndex], (long)[self.currentlySelectedDate dayIndex]);
    
    if ([self onceMode]) {
        // month, day, year
        [self.dayPicker selectRow:[self.currentlySelectedDate monthIndex] inComponent:0 animated:NO];
        [self.dayPicker selectRow:[self.currentlySelectedDate dayIndex] inComponent:1 animated:NO];
        [self.dayPicker selectRow:[self.currentlySelectedDate yearIndex] inComponent:2 animated:NO];
    } else if ([self yearlyMode]) {
        [self.dayPicker selectRow:[self.currentlySelectedDate monthIndex] inComponent:1 animated:NO];
        [self.dayPicker selectRow:[self.currentlySelectedDate dayIndex] inComponent:2 animated:NO];
    } else if ([self monthlyMode]) {
        [self.dayPicker selectRow:[self.currentlySelectedDate dayIndex] inComponent:1 animated:NO];
    } else if ([self weeklyMode]) {
        [self.dayPicker selectRow:[self.currentlySelectedDate dayOfWeekIndex] inComponent:1 animated:NO];
    } else if ([self dailyMode]) {
        
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






# pragma mark picker view delegate data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
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
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ([self onceMode]) {
        if (component == 0) {
            return 12;
        } else if (component == 1) {
            return [self.currentlySelectedDate daysInSelectedMonth];
        } else if (component == 2) {
            return 800;
        }
    } else if ([self yearlyMode]) {
        if (component == 0) {
            return 1;
        } else if (component == 1) {
            return 12;
        } else if (component == 2) {
            return [self.currentlySelectedDate daysInSelectedMonth];
        }
    } else if ([self monthlyMode]) {
        if (component == 0) {
            return 1;
        } else if (component == 1) {
            return [self.currentlySelectedDate daysInSelectedMonth];
        } else if (component == 2) {
            return 1;
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
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if ([self onceMode]) {
        if (component == 0) {
            return [[NSArray months] objectAtIndex:row];
        } else if (component == 1) {
            int year = (int)[NSDate currentYearInteger]+(int)[pickerView selectedRowInComponent:2];
            int month = (int)[pickerView selectedRowInComponent:0]+1;
            int day = (int)row+1;
            return [NSString stringWithFormat:@"%i (%@)", (int)row+1, [[NSArray daysOfWeekShort] objectAtIndex:[[NSDate timeWithString:[NSString stringWithFormat:@"%i-%@%i-%@%i", year, (month < 10 ? @"0" : @""), month, (day < 10 ? @"0" : @""), day]] dayOfWeekIndex]]];
        } else if (component == 2) {
            return [NSString stringWithFormat:@"%i", (int)[NSDate currentYearInteger]+(int)row];
        }
    } else if ([self yearlyMode]) {
        if (component == 0) {
            return @"every";
        } else if (component == 1) {
            return [[NSArray months] objectAtIndex:row];
        } else if (component == 2) {
            return [NSString stringWithFormat:@"%i", (int)row+1];
        }
    } else if ([self monthlyMode]) {
        if (component == 0) {
            return @"the";
        } else if (component == 1) {
            return [NSString stringWithFormat:@"%i", (int)row+1];
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
    return 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel* label = (UILabel*)view;
    if (!label) {
        label = [[UILabel alloc] init];
        [label setFont:[UIFont titleFontWithSize:15.0f]];
        [label setNumberOfLines:1];
        [label setTextAlignment:NSTextAlignmentCenter];
    }
    [label setText:[self pickerView:pickerView titleForRow:row forComponent:component]];
    return label;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    float screenWidth = self.view.frame.size.width - (24.0f*([pickerView numberOfComponents]-1)) - 32.0f;
    //float smallWidth = screenWidth/7.0f;
    float numberWidth = 40.0f;
    float yearWidth = 80.0f;
    
    if ([self onceMode]) {
        if (component == 0) {
            return (screenWidth-yearWidth)/2.0f;
        } else if (component == 1) {
            return (screenWidth-yearWidth)/2.0f;
        } else if (component == 2) {
            return yearWidth;
        }
    } else if ([self yearlyMode]) {
        if (component == 0) {
            return (screenWidth-numberWidth)/4.0f;
        } else if (component == 1) {
            return (screenWidth-numberWidth)*2.0f/3.0f;
        } else if (component == 2) {
            return numberWidth;
        }
    } else if ([self monthlyMode]) {
        if (component == 0) {
            return (screenWidth-numberWidth)/5.0f;
        } else if (component == 1) {
            return numberWidth;
        } else if (component == 2) {
            return (screenWidth-numberWidth);
        }
    } else if ([self weeklyMode]) {
        if (component == 0) {
            return screenWidth/4.0f;
        } else if (component == 1) {
            return screenWidth*3.0f/4.0f;
        }
    } else if ([self dailyMode]) {
        return screenWidth;
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self refreshAfterSelect];
}

- (IBAction) typeAction:(id)sender
{
    [self refreshDayPicker];
}

- (NSDate*) createDateFromDayPicker
{
    int year = (int)[NSDate currentYearInteger];
    int month = (int)[NSDate currentMonthInteger];
    int day = (int)[NSDate currentDayInteger];
    if ([self onceMode]) {
        // month, day, year
        month = (int)[self.dayPicker selectedRowInComponent:0]+1;
        day = (int)[self.dayPicker selectedRowInComponent:1]+1;
        year = (int)[self.dayPicker selectedRowInComponent:2]+(int)[NSDate currentYearInteger];
    } else if ([self yearlyMode]) {
        month = (int)[self.dayPicker selectedRowInComponent:1]+1;
        day = (int)[self.dayPicker selectedRowInComponent:2]+1;
    } else if ([self monthlyMode]) {
        month = 1; //so that there are always 31 available days
        day = (int)[self.dayPicker selectedRowInComponent:1]+1;
    } else if ([self weeklyMode]) {
        int todayIndex = (int)[[NSDate date] dayOfWeekIndex];
        int toIndex = (int)[self.dayPicker selectedRowInComponent:1];
        return [[NSDate date] dateByAddingTimeInterval:(60*60*24*(toIndex-todayIndex))];
    } else if ([self dailyMode]) {
        
    }
    if ([NSArray daysInMonthAtIndex:(month-1) forYear:year] < day) {
        day = [NSArray daysInMonthAtIndex:(month-1) forYear:year];
    }
    NSString* format = [NSString stringWithFormat:@"%i-%@%i-%@%i", year, (month < 10 ? @"0" : @""), month, (day < 10 ? @"0" : @""), day];
    return [NSDate timeWithString:format];
}



# pragma mark helper methods

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}

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
    if ([self.typeSegmentedControl selectedSegmentIndex] < [self.typeOptions count]) {
        return [self.typeOptions objectAtIndex:[self.typeSegmentedControl selectedSegmentIndex]];
    }
    return @"once";
}




#pragma mark actions

- (IBAction)saveAction:(id)sender
{
    NSMutableDictionary* item = [self item];
    if (item) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZ"];
        NSString* newDate = [dateFormat stringFromDate:self.currentlySelectedDate];
        
        [item saveRemoteWithNewAttributes:@{@"reminder_date":newDate, @"item_type":[self typeSelected]} success:nil failure:nil];
    }
    [self dismissViewControllerAnimated:NO completion:^(void){}];
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)backgroundTapAction:(id)sender
{
    [self cancelAction:sender];
}

- (IBAction)removeAction:(id)sender
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];
    [comps setMonth:1];
    [comps setYear:1970];
    self.currentlySelectedDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    [self.typeSegmentedControl setSelectedSegmentIndex:0]; 
    [self saveAction:sender];
}

@end
