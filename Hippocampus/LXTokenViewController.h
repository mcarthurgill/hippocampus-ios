//
//  LXTokenViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 1/20/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXTokenViewController : UIViewController
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) NSString* phoneNumber;
@property (strong, nonatomic) IBOutlet UITextField *tokenInput;

- (IBAction)goAction:(id)sender;

@end
