//
//  SHNewBucketTableViewCell.m
//  Hippocampus
//
//  Created by Joseph Gill on 11/12/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHNewBucketTableViewCell.h"

@implementation SHNewBucketTableViewCell

- (void)awakeFromNib {
    [self setupTableViewCell];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

# pragma mark Setup
- (void)setupTableViewCell
{
    [self.titleLabel setFont:[UIFont titleFontWithSize:15.0f]];
    [self.titleLabel setTextColor:[UIColor SHFontDarkGray]];
    [self.titleLabel setText:@"New Bucket"];
    
    [self.defaultView setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.contentView setBackgroundColor:[UIColor clearColor]];
    
    [self.typingView setHidden:YES];
    [self.defaultView setHidden:NO];
}

# pragma mark Actions

- (IBAction)saveBucketAction:(id)sender {
    if ([self.bucketNameTextField text] && [[self.bucketNameTextField text] length] > 0) {
        [self addBucketWithText:[self.bucketNameTextField text]];
    }
    [self.bucketNameTextField setText:@""];

}

- (void) addBucketWithText:(NSString*)text
{
    //CREATE BUCKET
    NSMutableDictionary* newBucket = [NSMutableDictionary create:@"bucket"];
    [newBucket setObject:text forKey:@"first_name"];
    [newBucket assignLocalVersionIfNeeded:YES];
    [NSMutableDictionary addRecentBucketLocalKey:[newBucket localKey]];
    [newBucket saveRemote:^(id responseObject){
        [NSMutableDictionary bucketKeysWithSuccess:^(id responseObject){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedBucketLocalKeys" object:nil userInfo:nil];
        }failure:nil];
    }failure:nil];
    [self toggleNewBucket];
}
- (IBAction)tappedNewBucketAction:(id)sender
{
    [self toggleNewBucket];
}

- (void) toggleNewBucket
{
    [self.defaultView setHidden:!self.defaultView.isHidden];
    [self.typingView setHidden:!self.typingView.isHidden];
    if (![self inDefaultMode]) {
        [self.bucketNameTextField becomeFirstResponder];
    } else {
        [self.bucketNameTextField resignFirstResponder];
    }
}

- (void) setViewBackToDefault
{
    if (![self inDefaultMode]) {
        [self.defaultView setHidden:NO];
        [self.typingView setHidden:YES];
        [self.bucketNameTextField setText:@""]; 
        [self.bucketNameTextField resignFirstResponder];
    }
}

- (BOOL) inDefaultMode
{
    return [self.typingView isHidden];
}

@end
