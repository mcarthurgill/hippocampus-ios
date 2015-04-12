//
//  HCNameViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCNameViewController.h"

@protocol HCSendInvitesDelegate <NSObject>
-(void)alertBeforeSendingInvites;
-(void)updateUserShareThreadCount;
@end

@interface HCNameViewController ()

@end

@implementation HCNameViewController

@synthesize nameTextField;
@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)continueAction:(id)sender {
    if (nameTextField.text && nameTextField.text.length > 0) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.nameTextField.text, @"name", nil];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:dict, @"user", nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[LXServer shared] updateUser:params success:nil failure:nil];
        });
        
        [self dismissViewControllerAnimated:YES completion:^(void) {
            [self.delegate updateUserShareThreadCount];
            [self.delegate alertBeforeSendingInvites];
        }];
    }
}

@end
