//
//  SHDismissFeatureViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 12/11/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHDismissFeatureViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *button;

- (IBAction)buttonAction:(id)sender;

@end
