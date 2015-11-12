//
//  SHNewBucketTableViewCell.h
//  Hippocampus
//
//  Created by Joseph Gill on 11/12/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHNewBucketTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *typingView;
@property (weak, nonatomic) IBOutlet UIView *defaultView;
@property (weak, nonatomic) IBOutlet UITextField *bucketNameTextField;

- (IBAction)saveBucketAction:(id)sender;
- (IBAction)tappedNewBucketAction:(id)sender;
- (void) toggleNewBucket;
- (void) setViewBackToDefault;
- (BOOL) inDefaultMode;

@end
