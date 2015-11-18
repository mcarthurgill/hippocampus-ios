//
//  SHMediaPlayerViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/21/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;

@interface SHMediaPlayerViewController : UIViewController

@property (strong, nonatomic) NSDictionary* medium;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *topRightButton;
@property (strong, nonatomic) IBOutlet UIButton *overlayButton;

@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) AVPlayerLayer* playerLayer;
@property (strong, nonatomic) AVAsset* asset;
@property (strong, nonatomic) AVPlayerItem* playerItem;

- (IBAction)topRightAction:(id)sender;
- (IBAction)overlayButtonAction:(id)sender;

@end
