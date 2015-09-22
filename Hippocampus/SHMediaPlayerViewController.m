//
//  SHMediaPlayerViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/21/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHMediaPlayerViewController.h"

@interface SHMediaPlayerViewController ()

@end

@implementation SHMediaPlayerViewController

@synthesize medium;
@synthesize imageView;
@synthesize topRightButton;
@synthesize overlayButton;

@synthesize player, playerLayer, asset, playerItem;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupMedia];
    
    [[self.topRightButton titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.topRightButton setAlpha:1.0f];
    [UIView animateWithDuration:0.5f delay:0.8f options:0 animations:^(void){
        [self.topRightButton setAlpha:0.0f];
    } completion:^(BOOL finished){
    }];
}

- (void) setupMedia
{
    if ([self.medium isVideo]) {
        [self setupVideo];
    } else {
        [self setupImage];
    }
}

- (void) setupImage
{
    [self.imageView loadInImageWithRemoteURL:[self.medium mediaThumbnailURLWithScreenWidth] localURL:[self.medium objectForKey:@"local_file_name"]];
}

- (void) setupVideo
{
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.imageView setHidden:YES];
    if (!self.player) {
        
        self.asset = [AVAsset assetWithURL:[NSURL URLWithString:[self.medium mediaURL]]];
        if (!self.playerItem) {
            self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
        }
        if (!self.player) {
            self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
            self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        }
        
        if (!self.playerLayer) {
            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
            [self.playerLayer setFrame:self.view.frame]; //CHANGE THIS LINE AND NEXT
            [self.view.layer addSublayer:self.playerLayer];
        }
        [self.player play];
    }
    [self.view bringSubviewToFront:self.overlayButton];
    [self.view bringSubviewToFront:self.topRightButton];
}



# pragma mark actions

- (IBAction)topRightAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^(void){}];
}

- (IBAction)overlayButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:^(void){}];
}

- (void) playerItemDidReachEnd:(NSNotification*)notification
{
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}



- (BOOL) prefersStatusBarHidden {
    return YES;
}

@end
