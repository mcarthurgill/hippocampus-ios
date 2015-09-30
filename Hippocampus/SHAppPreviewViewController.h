//
//  SHAppPreviewViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/29/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;

@interface SHAppPreviewViewController : UIViewController

@property (strong, nonatomic) MPMoviePlayerController* moviePlayer;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic) IBOutlet UIButton *topRightButton;

- (IBAction)topRightButtonAction:(id)sender;

@end
