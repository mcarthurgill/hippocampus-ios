//
//  SHAssignTagTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 10/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAssignTagTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

- (void) configureWithTagLocalKey:(NSString*)lk;

@end
