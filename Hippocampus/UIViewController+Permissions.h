//
//  UIViewController+Permissions.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/25/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MessageUI;

@interface UIViewController (Permissions) <MFMailComposeViewControllerDelegate>

- (void) permissionsDelegate:(NSString*)type;

@end
