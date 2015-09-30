//
//  SHAppPreviewViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/29/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHAppPreviewViewController.h"

@interface SHAppPreviewViewController ()

@end

@implementation SHAppPreviewViewController

@synthesize moviePlayer;
@synthesize videoView;
@synthesize topRightButton;

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupAppearance
{
    [[self.topRightButton titleLabel] setFont:[UIFont titleFontWithSize:14.0f]];
    [self.topRightButton setTintColor:[UIColor SHColorBlue]];
}

- (void) setupVideo
{
    if (!self.moviePlayer) {
        NSString*thePath=[[NSBundle mainBundle] pathForResource:@"HippoPreview" ofType:@"mp4"];
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
}

- (void) playBackFinished:(NSNotification*)notification
{
    NSLog(@"playback finished!");
}

# pragma mark finished

- (IBAction)topRightButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}


@end
