//
//  UIViewController+Permissions.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/25/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "UIViewController+Permissions.h"
#import "NSString+SHAEncryption.h"

@implementation UIViewController (Permissions)

- (void) permissionsDelegate:(NSString*)type
{
    UIViewController* vc;
    if ([type isEqualToString:@"email"]) {
        vc = [self emailSetterViewController];
    }
    [self presentViewController:vc animated:YES completion:^(void){}];
}





# pragma mark view controllers

- (UIViewController*) emailSetterViewController
{
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:[NSString stringWithFormat:@"My Token: (%@==%@", [NSString userAuthToken], [[[LXSession thisSession] user] ID]]];
    [mc setMessageBody:@"Hit 'Send' in the top right corner to verify this email address! (and don't delete/change the subject of this email)\n\nVerify me! Cheers," isHTML:NO];
    [mc setToRecipients:@[@"thought@hppcmps.com"]];
    [mc.view setTag:1];
    return mc;
}




# pragma mark mail delegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            if ([controller.view tag] == 1) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"askedPermission" object:nil userInfo:@{@"type":@"email"}];
            }
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

@end
