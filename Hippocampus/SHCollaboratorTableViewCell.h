//
//  SHCollaboratorTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHCollaboratorTableViewCell : UITableViewCell

@property (strong, nonatomic) NSString* localKey;
@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) NSDictionary* collaborator;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *label;

- (void) configureWithLocalKey:(NSString*)lk delegate:(id)d collaborator:(NSDictionary*)c;

@end
