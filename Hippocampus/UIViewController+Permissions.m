//
//  UIViewController+Permissions.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/25/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "UIViewController+Permissions.h"
#import "NSString+SHAEncryption.h"
#import "SHAssignBucketsViewController.h"

@import PermissionScope;

@implementation UIViewController (Permissions)

- (void) permissionsDelegate:(NSString*)type
{
    UIViewController* vc;
    if ([type isEqualToString:@"email"]) {
        vc = [self emailSetterViewController];
    }
    [self presentViewController:vc animated:YES completion:^(void){}];
}

- (void) prePermissionsDelegate:(NSString*)type message:(NSString*)message
{
    if ([[[LXSession thisSession] permissionsAsked] objectForKey:type] || ![[self.navigationController topViewController] isKindOfClass:[self class]])
        return;
    
    PermissionScope* pscope = [[PermissionScope alloc] init];
    [pscope setViewControllerForAlerts:pscope];
    
    [[[pscope closeButton] titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
    [pscope setCloseButtonTextColor:[UIColor SHBlue]];
    
    [pscope setAuthorizedButtonColor:[UIColor SHColorBlue]];
    [pscope setUnauthorizedButtonColor:[UIColor SHColorOrange]];
    
    [pscope setButtonFont:[UIFont titleFontWithSize:14.0f]];
    [pscope setLabelFont:[UIFont secondaryFontWithSize:15.0f]];
    
    [[pscope headerLabel] setFont:[UIFont titleFontWithSize:16.0f]];
    
    [[pscope bodyLabel] setFont:[UIFont secondaryFontWithSize:15.0f]];
    [[pscope bodyLabel] setTextColor:[UIColor SHFontDarkGray]];
    [[pscope bodyLabel] setNumberOfLines:0];
    
    [pscope setPermissionLabelColor:[UIColor SHFontDarkGray]];
    
    [[pscope bodyLabel] setText:message];
    if ([type isEqualToString:@"notifications"]) {
        [[pscope headerLabel] setText:@"Do you want notifications?"];
        [pscope addPermission:[[NotificationsPermission alloc] initWithNotificationCategories:nil] message:@"Tap to enable."];
        
        //UIUserNotificationType types = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
        //UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    } else if ([type isEqualToString:@"contacts"]) {
        [[pscope headerLabel] setText:@"Use Address Book?"];
        [pscope addPermission:[[ContactsPermission alloc] init] message:@"Tap to enable."];
    } else if ([type isEqualToString:@"location"]) {
        [[pscope headerLabel] setText:@"Add your location?"];
        [pscope addPermission:[[LocationWhileInUsePermission alloc] init] message:@"Tap to enable."];
    }
    
    [pscope show:^(BOOL finished, NSArray* result){
        NSLog(@"result: %@", result);
        if ([type isEqualToString:@"contacts"]) {
            [[LXAddressBook thisBook] requestAccess:^(BOOL success) {
                [(SHAssignBucketsViewController*)self performSelector:@selector(reloadScreen) withObject:nil afterDelay:0.01];
            }];
        }
    } cancelled:^(NSArray* result){
        NSLog(@"cancelled: %@", result);
        [pscope hide];
    }];
    
    [[[LXSession thisSession] permissionsAsked] setObject:@YES forKey:type];
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
