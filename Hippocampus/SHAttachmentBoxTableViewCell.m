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
@synthesize attachmentType;

@synthesize card;
@synthesize leftImageView;
@synthesize separatorView;

@synthesize topLabel;
@synthesize centerLabel;
@synthesize rightLabel;

@synthesize verticalSpaceBetweenLabels;
@synthesize leftAlignmentForBottomLabel;

- (void)awakeFromNib
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.card.layer.cornerRadius = 4.0f;
    [self.card setClipsToBounds:YES];
    
    [self.card.layer setBorderWidth:1.0f];
    [self.card.layer setBorderColor:[UIColor SHLightGray].CGColor];
    
    [self.separatorView setBackgroundColor:[UIColor SHLightGray]];
    
    [self.topLabel setFont:[UIFont secondaryFontWithSize:12.0f]];
    [self.topLabel setTextColor:[UIColor SHFontLightGray]];
    
    [self.centerLabel setFont:[UIFont titleMediumFontWithSize:18.0f]];
    [self.centerLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [self.rightLabel setFont:[UIFont secondaryFontWithSize:12.0f]];
    [self.rightLabel setTextColor:[UIColor SHFontLightGray]];
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

- (void) configureWithLocalKey:(NSString*)key attachment:(NSMutableDictionary*)attchmnt type:(NSString*)type
{
    [self setLocalKey:key];
    [self setAttachmentType:type];
    [self setAttachment:attchmnt];
    
    [self hideSubviewsOfCard];
    
    if ([self isBucketType]) {
        [self configureForBucket];
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void) hideSubviewsOfCard
{
    for (UIView* subview in [self.card subviews]) {
        if (!([subview tag] > 0)) {
            [subview setHidden:YES];
        }
    }
}

- (void) configureForBucket
{
    [self.leftImageView setImage:[UIImage imageNamed:@"bucket_detail_icon.png"]];
    
    NSMutableDictionary* bucket = [LXObjectManager objectWithLocalKey:[self.attachment localKey]] ? [LXObjectManager objectWithLocalKey:[self.attachment localKey]] : self.attachment;
    
    NSLog(@"bucket: %@", bucket);
    
    [self.centerLabel setHidden:NO];
    [self.centerLabel setText:[NSString stringWithFormat:@"  %@  ",[bucket firstName]]];
    [self.centerLabel setBackgroundColor:[bucket bucketColor]];
    [self.centerLabel setTextColor:[UIColor whiteColor]];
    [self.centerLabel.layer setCornerRadius:15.5];
    [self.centerLabel setClipsToBounds:YES];
    
    [self.rightLabel setHidden:NO];
    [self.rightLabel setText:[NSString stringWithFormat:@"%@ Thoughts", [bucket itemsCount]]];
    
    self.leftAlignmentForBottomLabel.constant = 10;
    self.verticalSpaceBetweenLabels.constant = 2;
}



# pragma mark types

- (BOOL) isBucketType
{
    return [self.attachmentType isEqualToString:@"bucket"];
}

@end
