//
//  HCDetailsPhotoTableViewCell.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCBucketDetailsViewController.h"

@interface HCDetailsPhotoTableViewCell : UITableViewCell

- (void)configureWithMediaUrl:(NSString*)mediaUrl andImageView:(UIImageView*)imageView;

@end
