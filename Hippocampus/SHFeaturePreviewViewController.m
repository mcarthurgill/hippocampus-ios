//
//  SHFeaturePreviewViewController.m
//  Hippocampus
//
//  Created by Joseph Gill on 12/10/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHFeaturePreviewViewController.h"

@interface SHFeaturePreviewViewController ()

@end

@implementation SHFeaturePreviewViewController

@synthesize moviePlayer;
@synthesize videoView;
@synthesize featureDescriptionLabel;
@synthesize resourceName; 
@synthesize index;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupAppearance];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setupVideo];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self removeAbilityToGoBack];
    [self removeTop];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark setup

- (void) removeAbilityToGoBack
{
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    self.navigationItem.hidesBackButton = YES;
}

- (void) removeTop
{
    [self.navigationController setNavigationBarHidden:YES];
}

- (void) setupAppearance
{
    [self.featureDescriptionLabel setText:self.descriptionText];
    [self.featureDescriptionLabel setFont:[UIFont secondaryFontWithSize:18.0f]];
    [self.featureDescriptionLabel setTextColor:[UIColor SHFontDarkGray]];
}

- (void) setupVideo
{
    [self createMoviePlayer];
}

- (void) createMoviePlayer
{
    NSString*thePath=[[NSBundle mainBundle] pathForResource:self.resourceName ofType:@"mp4"];
    NSURL*theurl=[NSURL fileURLWithPath:thePath];
    
    NSLog(@"%@, %@", thePath, theurl);
    
    self.moviePlayer=[[MPMoviePlayerController alloc] initWithContentURL:theurl];
    [self.moviePlayer.view setFrame:CGRectMake(0, 0, self.videoView.frame.size.width, self.videoView.frame.size.height)];
    
    self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    self.moviePlayer.fullscreen = NO;
    self.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer setShouldAutoplay:YES]; // And other options you can look through the documentation.
    [self.videoView addSubview:self.moviePlayer.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
}

- (void) playBackFinished:(NSNotification*)notification
{
    NSLog(@"playback finished!");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [self.moviePlayer stop];
    self.moviePlayer.initialPlaybackTime = -1;
    
    self.moviePlayer = nil;
}


# pragma mark status bar

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
