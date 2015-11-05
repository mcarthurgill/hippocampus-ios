//
//  SHLinkMetadataTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 11/4/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHLinkMetadataTableViewCell.h"
#import "SHItemViewController.h"

@implementation SHLinkMetadataTableViewCell

@synthesize localKey;
@synthesize delegate;

@synthesize leftImageView;
@synthesize leftImageViewHeightConstraint;
@synthesize leftImageViewWidthConstraint;
@synthesize topLabel;
@synthesize middleLabel;
@synthesize bottomLabel;

@synthesize leftLabel;

- (void)awakeFromNib
{
    [self.leftImageView setClipsToBounds:YES];
    [self.leftImageView.layer setBorderColor:[UIColor SHLighterGray].CGColor];
    [self.leftImageView.layer setCornerRadius:4.0f];
    [self.leftImageView.layer setBorderWidth:1.0f];
    [self.leftImageView setBackgroundColor:[UIColor SHLighterGray]];
    
    [self.topLabel setFont:[UIFont titleFontWithSize:14.0f]];
    [self.topLabel setTextColor:[UIColor SHBlue]];
    
    [self.middleLabel setFont:[UIFont titleFontWithSize:14.0f]];
    [self.middleLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [self.bottomLabel setFont:[UIFont secondaryFontWithSize:13.0f]];
    [self.bottomLabel setTextColor:[UIColor SHFontLightGray]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.leftLabel setBackgroundColor:[UIColor SHFontLightGray]];
    [self.leftLabel.layer setCornerRadius:1.0f];
    [self.leftLabel setClipsToBounds:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


# pragma mark helpers

- (NSMutableDictionary*) link
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}


- (void) configureWithLinkURLString:(NSString*)linkURL delegate:(id)d
{
    [self setLocalKey:[linkURL linkLocalKeyFromURLString]];
    [self setDelegate:d];
    
    if (![self link]) {
        [[LXObjectManager defaultManager] refreshObjectWithKey:self.localKey
                                                       success:^(id responseObject){
                                                           [(SHItemViewController*)delegate reloadScreen];
                                                       } failure:^(NSError* error){}
         ];
        [self.leftImageView setImage:nil];
        [self.topLabel setText:nil];
        [self.middleLabel setText:nil];
        [self.bottomLabel setText:nil];
        self.leftImageViewHeightConstraint.constant = 0.0f;
        [self.leftLabel setHidden:YES];
        [self setNeedsLayout];
        return;
    }
    
    [self.leftLabel setHidden:NO];
    
    if ([[self link] bestImage]) {
        [self.leftImageView loadInImageWithRemoteURL:[[self link] objectForKey:@"best_image"] localURL:nil];
        self.leftImageViewWidthConstraint.constant = 80.0f;
        self.leftImageViewHeightConstraint.constant = 80.0f;
    } else {
        [self.leftImageView setImage:nil];
        self.leftImageViewWidthConstraint.constant = 0.0f;
        self.leftImageViewHeightConstraint.constant = 0.0f;
    }
    
    [self.topLabel setText:[[self link] URLString]];
    
    [self.middleLabel setText:[[self link] bestTitle]];
    
    //[self.bottomLabel setText:[NSString stringWithFormat:@"%@",[[self link] bestDescription]]];
    [self.bottomLabel setText:[[self link] bestDescription]];
    
    [self setNeedsLayout];
}

@end
