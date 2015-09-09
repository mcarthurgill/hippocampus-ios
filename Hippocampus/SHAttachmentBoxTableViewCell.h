//
//  SHAttachmentBoxTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAttachmentBoxTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString* localKey;
@property (strong, nonatomic) NSDictionary* attachment;

@property (strong, nonatomic) IBOutlet UIView *card;
@property (strong, nonatomic) IBOutlet UIImageView *leftImageView;
@property (strong, nonatomic) IBOutlet UIView *separatorView;

- (void) configureWithLocalKey:(NSString*)key attachment:(NSDictionary*)attchmnt;

@end
