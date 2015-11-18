//
//  SHContactTableViewCell.m
//  Hippocampus
//
//  Created by Joseph Gill on 9/18/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHContactTableViewCell.h"

@implementation SHContactTableViewCell

- (void)awakeFromNib {
    [self.nameLabel setFont:[UIFont titleFontWithSize:16.0f]];
    [self.nameLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [self.phoneLabel setFont:[UIFont titleFontWithSize:10.0f]];
    [self.phoneLabel setTextColor:[UIColor SHFontLightGray]];

    [self.contactImageView.layer setCornerRadius:16.0f];
    [self.contactImageView setClipsToBounds:YES];
    
    self.contactImageView.image = [UIImage imageNamed:@"avatar.png"];
    self.addedImageView.image = [UIImage imageNamed:@"filled_check.png"];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) configureWithContact:(NSMutableDictionary *)contact andSelectedContacts:(NSMutableArray*)sc
{
    [self setContact:contact];
    [self setSelectedContacts:sc]; 
    [self setupUserImage];
    [self setupAddedImage];
    [self setupUserName];
    [self setupUserPhone];
}

- (void) setupUserImage
{
    [self.contactImageView setBackgroundColor:[UIColor SHLighterGray]];
    UIImage *contactImage = [self.contact objectForKey:@"image"];
    if (contactImage) {
        [UIView animateWithDuration:0.3 animations:^(void){
            [self.contactImageView setImage:contactImage];
        }];
    } else {
        self.contactImageView.image = [UIImage imageNamed:@"avatar.png"];
    }
}

- (void) setupAddedImage
{
    [self.selectedContacts containsObject:self.contact] ? [self.addedImageView setHidden:NO] : [self.addedImageView setHidden:YES];
}

- (void) setupUserName
{
    [self.nameLabel setText:[self.contact name]];
    if ([[LXAddressBook thisBook] sortedByFirstName]) {
        [self.nameLabel boldSubstring:[self.contact firstName]];
    } else {
        [self.nameLabel boldSubstring:[self.contact lastName]];
    }
}

- (void) setupUserPhone
{
    [self.phoneLabel setText:[[self.contact phones] firstObject]];
}

- (void) selectedContact
{
    self.addedImageView.hidden ? [self.addedImageView setHidden:NO] : [self.addedImageView setHidden:YES];
}
@end
