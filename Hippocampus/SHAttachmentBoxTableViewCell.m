//
//  SHAttachmentBoxTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHAttachmentBoxTableViewCell.h"
#import "SHItemViewController.h"

#define IMAGE_FADE_IN_TIME 0.4f

@implementation SHAttachmentBoxTableViewCell

@synthesize delegate;

@synthesize localKey;
@synthesize attachment;
@synthesize attachmentType;

@synthesize longPress;

@synthesize card;
@synthesize leftImageView;
@synthesize separatorView;

@synthesize topLabel;
@synthesize centerLabel;
@synthesize rightLabel;

@synthesize centerLabelHeight;
@synthesize verticalSpaceBetweenLabels;
@synthesize leftAlignmentForBottomLabel;
@synthesize centerLabelCenterY;

@synthesize initialConstraintConstants;

- (void) awakeFromNib
{
    self.initialConstraintConstants = @[@(centerLabelHeight.constant), @(verticalSpaceBetweenLabels.constant), @(leftAlignmentForBottomLabel.constant), @(centerLabelCenterY.constant)];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.card.layer.cornerRadius = 4.0f;
    [self.card setClipsToBounds:YES];
    
    [self.card.layer setBorderWidth:1.0f];
    [self.card.layer setBorderColor:[UIColor SHLightGray].CGColor];
    
    [self.separatorView setBackgroundColor:[UIColor SHLightGray]];
    
    [self setupGestureRecognizers];
}

- (void) resetAppearance
{
    [self.topLabel setFont:[UIFont secondaryFontWithSize:12.0f]];
    [self.topLabel setTextColor:[UIColor SHFontLightGray]];
    
    [self.centerLabel setFont:[UIFont titleMediumFontWithSize:18.0f]];
    [self.centerLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [self.rightLabel setFont:[UIFont secondaryFontWithSize:12.0f]];
    [self.rightLabel setTextColor:[UIColor SHFontLightGray]];
    
    [self.topLabel setBackgroundColor:[UIColor clearColor]];
    [self.centerLabel setBackgroundColor:[UIColor clearColor]];
    [self.rightLabel setBackgroundColor:[UIColor clearColor]];
    
    self.centerLabelHeight.constant = [self.initialConstraintConstants[0] floatValue];
    self.verticalSpaceBetweenLabels.constant = [self.initialConstraintConstants[1] floatValue];
    self.leftAlignmentForBottomLabel.constant = [self.initialConstraintConstants[2] floatValue];
    self.centerLabelCenterY.constant = [self.initialConstraintConstants[3] floatValue];
}

- (void) setupGestureRecognizers
{
    if (!self.longPress) {
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [self addGestureRecognizer:longPress];
    }
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
    
    [self resetAppearance];
    [self hideSubviewsOfCard];
    
    if ([self isBucketType]) {
        [self configureForBucket];
    } else if ([self isNudgeType]) {
        [self configureForNudge];
    } else if ([self isAudioType]) {
        [self configureForAudio];
    } else if ([self isEmailType]) {
        [self configureForEmail];
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
    
    //NSLog(@"bucket: %@", bucket);
    
    [self.centerLabel setHidden:NO];
    [self.centerLabel setText:[NSString stringWithFormat:@"   %@   ",[bucket firstName]]];
    [self.centerLabel setBackgroundColor:[bucket bucketColor]];
    [self.centerLabel setTextColor:[UIColor whiteColor]];
    [self.centerLabel setFont:[UIFont secondaryFontWithSize:13.0f]];
    [self.centerLabel.layer setCornerRadius:11];
    [self.centerLabel setClipsToBounds:YES];
    
    [self.rightLabel setHidden:NO];
    [self.rightLabel setText:[NSString stringWithFormat:@"%@ Thoughts", [bucket itemsCount]]];
    
    self.centerLabelHeight.constant = 22.0f;
    self.leftAlignmentForBottomLabel.constant = 6;
    self.verticalSpaceBetweenLabels.constant = 2;
}

- (void) configureForNudge
{
    [self.leftImageView setImage:[UIImage imageNamed:@"nudge_detail_icon.png"]];
    
    if (![[[self.attachment itemType] lowercaseString] isEqualToString:@"daily"]) {
        [topLabel setHidden:NO];
    }
    [topLabel setText:[NSString stringWithFormat:@"%@ Nudge",([[self.attachment itemType] isEqualToString:@"once"] ? @"One-time" : [[self.attachment itemType] capitalizedString])]];
    
    [centerLabel setHidden:NO];
    [self.centerLabel setText:[self.attachment reminderDescriptionString]];
    [self.centerLabel setFont:[UIFont titleFontWithSize:16.0f]];
    
    if ([[[self.attachment itemType] lowercaseString] isEqualToString:@"once"]) {
        [self.rightLabel setHidden:NO];
        [self.rightLabel setText:[[NSDate timeWithString:[self.attachment reminderDate]] dayOfWeek]];
        self.verticalSpaceBetweenLabels.constant = -4;
        self.centerLabelCenterY.constant = 0;
    } else if ([[[self.attachment itemType] lowercaseString] isEqualToString:@"daily"]) {
        self.centerLabelCenterY.constant = 0;
    } else {
        self.centerLabelCenterY.constant = 8;
    }
}

- (void) configureForAudio
{
    [self.leftImageView setImage:[UIImage imageNamed:@"audio_detail_icon.png"]];
    
    [self.centerLabel setHidden:NO];
    [self.centerLabel setText:[NSString stringWithFormat:@"Tap to Play Audio File"]];
    [self.centerLabel setFont:[UIFont secondaryFontWithSize:15.0f]];
    self.centerLabelCenterY.constant = 0;
    
    //[self.bottomLabel setHidden:NO];
    //[self.bottomLabel setText:@"loading..."];
}

- (void) configureForEmail
{
    [self.leftImageView setImage:[UIImage imageNamed:@"audio_detail_icon.png"]];
    
    [self.centerLabel setHidden:NO];
    [self.centerLabel setText:[NSString stringWithFormat:@"View Original Email"]];
    [self.centerLabel setFont:[UIFont secondaryFontWithSize:15.0f]];
    self.centerLabelCenterY.constant = 0;
    
    //[self.bottomLabel setHidden:NO];
    //[self.bottomLabel setText:@"loading..."];
}

- (void) updateBottomLabel:(NSString *)string
{
    [self.bottomLabel setText:string];
}




# pragma mark types

- (BOOL) isBucketType
{
    return [self.attachmentType isEqualToString:@"bucket"];
}

- (BOOL) isNudgeType
{
    return [self.attachmentType isEqualToString:@"nudge"];
}

- (BOOL) isAudioType
{
    return [self.attachmentType isEqualToString:@"audio"];
}

- (BOOL) isEmailType
{
    return [self.attachmentType isEqualToString:@"email"];
}




# pragma mark actions

- (IBAction)longPressAction:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan){
        [(SHItemViewController*)delegate longPressWithObject:self.attachment type:self.attachmentType];
    }
}

@end
