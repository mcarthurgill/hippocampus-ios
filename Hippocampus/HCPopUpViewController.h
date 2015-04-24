//
//  HCPopUpViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/23/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCPopUpViewController : UIViewController
{
    CGRect mainFrame;
    CGRect hiddenFrame;
}

@property (weak, nonatomic) IBOutlet UIImageView *screenshotImageView;
@property (weak, nonatomic) IBOutlet UIView *tintedView;
@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;
@property (weak, nonatomic) IBOutlet UIButton *mainButton;

//the properties below are the ones you set for customization
@property (strong, nonatomic) UIImage *imageForMainImageView;
@property (strong, nonatomic) UIImage *imageForScreenshotImageView;
@property (strong, nonatomic) NSString *mainLabelText;

- (IBAction)mainButtonAction:(id)sender;
- (IBAction)backgroundButtonAction:(id)sender;


@end
