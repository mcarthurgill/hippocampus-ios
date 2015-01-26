//
//  HCNewBucketIITableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/9/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCNewBucketIITableViewController : UITableViewController <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) id delegate;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (strong, nonatomic) IBOutlet UIPickerView *typePicker;
@property (strong, nonatomic) IBOutlet UITextField *firstName;

@property (strong, nonatomic) NSArray* typeOptions;

- (IBAction)saveAction:(id)sender;

@end
