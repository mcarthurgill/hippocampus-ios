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
    
    if ([SGImageCache haveImageForURL:[self.item avatarURLString]]) {
        self.avatarView.image = [SGImageCache imageForURL:[self.item avatarURLString]];
        [self.avatarView setAlpha:1.0f];
        [self.avatarView viewWithTag:1].alpha = 0.0;
        [[self.avatarView viewWithTag:1] removeFromSuperview];
    } else if (![self.avatarView.image isEqual:[SGImageCache imageForURL:[self.item avatarURLString]]]) {
        self.avatarView.image = nil;
        [self.avatarView setAlpha:1.0f];
        [SGImageCache getImageForURL:[self.item avatarURLString]].then(^(UIImage* image) {
            if (image) {
                float curAlpha = [self.avatarView alpha];
                [self.avatarView setAlpha:0.0f];
                self.avatarView.image = image;
                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void){
                    [self.avatarView setAlpha:curAlpha];
                    [self.avatarView viewWithTag:1].alpha = 0.0;
                    [[self.avatarView viewWithTag:1] removeFromSuperview];
                }];
            }
        });
    }
    
    [self setNeedsLayout];
}


@end
