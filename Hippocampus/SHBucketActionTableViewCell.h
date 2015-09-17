//
//  SHBucketActionTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHBucketActionTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString* localKey;
@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) NSString* action;

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (void) configureWithLocalKey:(NSString*)lk delegate:(id)d action:(NSString*)a;

@end
