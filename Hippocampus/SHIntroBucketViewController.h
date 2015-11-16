//
//  SHIntroBucketViewController.h
//  Hippocampus
//
//  Created by Joseph Gill on 11/16/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHIntroBucketViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *bucketNameField;

- (IBAction)nextAction:(id)sender;

@end
