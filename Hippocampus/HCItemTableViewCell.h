//
//  HCItemTableViewCell.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCItemTableViewCell : UITableViewCell

- (void) configureWithItem:(NSDictionary*)item;
- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font;
- (NSString*) dateToDisplayForItem:(NSDictionary*)item;
@end
