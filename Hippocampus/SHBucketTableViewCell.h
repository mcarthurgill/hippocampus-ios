//
//  SHBucketTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHBucketTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString* bucketLocalKey;
- (void) configureWithBucketLocalKey:(NSString*)key;

@property (strong, nonatomic) IBOutlet UIView *card;
@property (strong, nonatomic) IBOutlet UILabel *bucketName;
@property (strong, nonatomic) IBOutlet UILabel *bucketItemMessage;

@end
