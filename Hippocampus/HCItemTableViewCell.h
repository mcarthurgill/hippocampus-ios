//
//  HCItemTableViewCell.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;

@protocol HCItemCellDelegate <NSObject>
- (void) actionTaken:(NSString*)action forItem:(NSDictionary *)i newItem:(NSMutableDictionary*)newI;
@end

@interface HCItemTableViewCell : MGSwipeTableCell <MGSwipeTableCellDelegate, UIActionSheetDelegate>
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) UIImageView* mediaView;
@property (strong, nonatomic) NSDictionary* item;

@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) AVPlayerLayer* playerLayer;
@property (strong, nonatomic) AVAsset* asset;
@property (strong, nonatomic) AVPlayerItem* playerItem;

- (void) configureWithItem:(NSDictionary*)itm;
- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font;
- (NSString*) dateToDisplayForItem:(NSDictionary*)item;

+ (CGFloat) heightForCellWithItem:(NSDictionary*)item;
+ (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font;

@end
