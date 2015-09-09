//
//  SHAttachmentBoxTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHAttachmentBoxTableViewCell.h"

#define IMAGE_FADE_IN_TIME 0.4f

@implementation SHAttachmentBoxTableViewCell

@synthesize localKey;
@synthesize attachment;

@synthesize card;
@synthesize leftImageView;
@synthesize separatorView;

- (void)awakeFromNib
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.card.layer.cornerRadius = 4.0f;
    [self.card setClipsToBounds:YES];
    
    [self.card.layer setBorderWidth:1.0f];
    [self.card.layer setBorderColor:[UIColor SHLightGray].CGColor];
    
    [self.separatorView setBackgroundColor:[UIColor SHLightGray]];
}


- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted) {
        [self.card setBackgroundColor:[UIColor SHLightGray]];
    } else {
        [self.card setBackgroundColor:[UIColor whiteColor]];
    }
}



# pragma mark helper

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}




# pragma mark configure

- (void) configureWithLocalKey:(NSString*)key attachment:(NSDictionary*)attchmnt
{
    [self setLocalKey:key];
    
    
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
