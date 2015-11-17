//
//  SHIntroThoughtViewController.h
//  Hippocampus
//
//  Created by Joseph Gill on 11/16/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHIntroThoughtViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UITextField *thoughtEntryTextField;
@property (strong, nonatomic) NSString *bucketLocalKey;

@end
