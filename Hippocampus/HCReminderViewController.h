//
//  HCReminderViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/11/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCReminderViewController : UIViewController

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (strong, nonatomic) NSDate* currentlySelectedDate;

@property (strong, nonatomic) IBOutlet UIPickerView *dayPicker;


@property (strong, nonatomic) NSArray* typeOptions;
@property (strong, nonatomic) IBOutlet UISegmentedControl *typeSegmentedControl;

@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;

- (IBAction)typeAction:(id)sender;

- (IBAction)saveAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)backgroundTapAction:(id)sender;

@end
