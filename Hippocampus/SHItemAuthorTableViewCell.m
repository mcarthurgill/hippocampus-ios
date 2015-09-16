//
//  SHItemAuthorTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemAuthorTableViewCell.h"

#define IMAGE_FADE_IN_TIME 0.4f
#define AVATAR_DIMENSION 32.0f

@implementation SHItemAuthorTableViewCell

@synthesize localKey;
@synthesize label;
@synthesize avatarView;

- (void)awakeFromNib
{
    [self.label setFont:[UIFont secondaryFontWithSize:12.0f]];
    [self.label setTextColor:[UIColor SHFontLightGray]];
    
    [self.avatarView setBackgroundColor:[UIColor SHFontLightGray]];
    [self.avatarView.layer setCornerRadius:(AVATAR_DIMENSION/2.0f)];
    [self.avatarView setClipsToBounds:YES];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}



# pragma mark helper

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}




# pragma mark configure

- (void) configureWithLocalKey:(NSString*)key
{
    [self setLocalKey:key];
    
    if ([[self item] hasAuthorName]) {
        [self.label setText:[NSString stringWithFormat:@"added by %@", [[self item] authorName]]];
    } else {
        [self.label setText:@""];
    }
    
    [self.avatarView loadInImageWithRemoteURL:[self.item avatarURLString] localURL:nil];
    
    [self setNeedsLayout];
}


@end
