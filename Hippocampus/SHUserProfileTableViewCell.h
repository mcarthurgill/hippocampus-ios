//
//  SHUserProfileTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/23/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHUserProfileTableViewCell : UITableViewCell

@property (strong, nonatomic) id delegate;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *imageButton;
@property (strong, nonatomic) IBOutlet UIButton *firstButton;
@property (strong, nonatomic) IBOutlet UIButton *secondButton;
@property (strong, nonatomic) IBOutlet UIButton *thirdButton;

- (void) configureWithDelegate:(id)d;

@end
