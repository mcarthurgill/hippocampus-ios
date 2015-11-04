//
//  SHLinkMetadataTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 11/4/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHLinkMetadataTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *leftImageView;
@property (strong, nonatomic) IBOutlet UILabel *topLabel;
@property (strong, nonatomic) IBOutlet UILabel *middleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bottomLabel;

@end
