//
//  HCNameViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCNameViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic,assign) id delegate;

- (IBAction)continueAction:(id)sender;

@end
