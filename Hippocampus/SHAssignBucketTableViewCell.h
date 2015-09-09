//
//  SHAssignBucketTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAssignBucketTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UIImageView *checkImage;

@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *preview;

- (void) configureWithBucketLocalKey:(NSString*)key;
- (void) configureWithContact:(NSMutableDictionary*)contact;

@end
