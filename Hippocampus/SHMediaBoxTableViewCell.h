//
//  SHMediaBoxTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

@interface SHMediaBoxTableViewCell : UITableViewCell

@property (strong, nonatomic) id delegate;

@property (strong, nonatomic) NSString* localKey;
@property (strong, nonatomic) NSDictionary* medium;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) UILongPressGestureRecognizer* longPress;

- (void) configureWithLocalKey:(NSString*)key medium:(NSDictionary*)m;

@end
