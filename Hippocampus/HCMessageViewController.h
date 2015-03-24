//
//  HCMessageViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 3/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCMessageViewController : UIViewController

@property (nonatomic) NSUInteger index;

@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) NSString* text;

- (void) setMessage:(NSString*)message;

@end
