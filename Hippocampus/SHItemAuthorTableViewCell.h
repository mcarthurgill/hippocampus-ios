//
//  SHItemAuthorTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHItemAuthorTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *avatarView;

- (void) configureWithLocalKey:(NSString*)key;

@end
