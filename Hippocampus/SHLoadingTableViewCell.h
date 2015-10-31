//
//  SHLoadingTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHLoadingTableViewCell : UITableViewCell
{
    BOOL inverted;
}

@property (strong, nonatomic) NSMutableDictionary* responseObject;
@property (strong, nonatomic) IBOutlet UILabel *label;

- (void) configureWithResponseObject:(NSMutableDictionary*)rO;

- (void) invertIfUpsideDown;
- (void) invert;

@end
