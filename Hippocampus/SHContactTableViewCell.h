//
//  SHContactTableViewCell.h
//  Hippocampus
//
//  Created by Joseph Gill on 9/18/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHContactTableViewCell : UITableViewCell

@property (strong, nonatomic) NSMutableDictionary *contact;
@property (strong, nonatomic) NSMutableArray *selectedContacts;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *contactImageView;
@property (weak, nonatomic) IBOutlet UIImageView *addedImageView;

- (void) configureWithContact:(NSMutableDictionary*)contact andSelectedContacts:(NSMutableArray*)sc; 
- (void) selectedContact;

@end
