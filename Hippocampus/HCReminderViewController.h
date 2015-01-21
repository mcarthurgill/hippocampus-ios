//
//  HCReminderViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/11/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCReminderViewController : UIViewController

@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) NSMutableDictionary* item;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;

- (IBAction)saveAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
