//
//  SHFeaturePreviewViewController.h
//  Hippocampus
//
//  Created by Joseph Gill on 12/10/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;

@interface SHFeaturePreviewViewController : UIViewController

@property (strong, nonatomic) MPMoviePlayerController* moviePlayer;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UILabel *featureDescriptionLabel;
@property (weak, nonatomic) NSString *resourceName; 
@property (weak, nonatomic) NSString *descriptionText; 
@property (nonatomic) NSUInteger index;

@end
