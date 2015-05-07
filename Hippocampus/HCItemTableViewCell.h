//
//  HCItemTableViewCell.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;

@interface HCItemTableViewCell : UITableViewCell

@property (strong, nonatomic) UIImageView* mediaView;
@property (strong, nonatomic) NSDictionary* item;

@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) AVPlayerLayer* playerLayer;
@property (strong, nonatomic) AVAsset* asset;
@property (strong, nonatomic) AVPlayerItem* playerItem;

- (void) configureWithItem:(NSDictionary*)item;
- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font;
- (NSString*) dateToDisplayForItem:(NSDictionary*)item;

@end
