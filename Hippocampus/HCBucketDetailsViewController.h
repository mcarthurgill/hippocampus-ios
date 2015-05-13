//
//  HCBucketDetailsViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/18/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>


#define PICTURE_HEIGHT 180
#define PICTURE_MARGIN_TOP 4

@protocol HCUpdateBucketDelegate <NSObject>
-(void)updateBucket:(NSMutableDictionary *)updatedBucket;
@end

@interface HCBucketDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL unsavedChanges;
    BOOL savingChanges;
    MBProgressHUD* hud;
}

@property (nonatomic,assign) id delegate;

@property (strong, nonatomic) NSMutableDictionary* bucket;
@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* actionCells;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSString *updatedBucketName;
@property (strong, nonatomic) NSDictionary *bucketUserPairForDeletion;

@property (strong, nonatomic) MPMoviePlayerViewController *moviePlayerController;

@property (strong, nonatomic) UIImageView* mediaView;
@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) AVPlayerLayer* playerLayer;
@property (strong, nonatomic) AVAsset* asset;
@property (strong, nonatomic) AVPlayerItem* playerItem;

@end
