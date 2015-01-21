//
//  HCEditItemViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 7/17/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCEditItemViewController : UIViewController

@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) NSMutableDictionary* item;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UITextView *editTextArea;

- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
