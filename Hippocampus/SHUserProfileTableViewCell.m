//
//  SHUserProfileTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/23/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHUserProfileTableViewCell.h"
#import "SHProfileViewController.h"

@implementation SHUserProfileTableViewCell

@synthesize delegate;

@synthesize imageView;
@synthesize imageButton;
@synthesize firstButton;
@synthesize secondButton;
@synthesize thirdButton;

- (void)awakeFromNib
{
    [self setupAppearance];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) setupAppearance
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.imageView.layer setCornerRadius:self.imageButton.bounds.size.width/2.0f];
    [self.imageView.layer setBorderColor:[UIColor SHLightGray].CGColor];
    [self.imageView setClipsToBounds:YES];
    [self.imageView setBackgroundColor:[UIColor SHLightGray]];
    
    [[self.firstButton titleLabel] setFont:[UIFont titleFontWithSize:16.0f]];
    [[self.secondButton titleLabel] setFont:[UIFont secondaryFontWithSize:13.0f]];
    [[self.thirdButton titleLabel] setFont:[UIFont secondaryFontWithSize:13.0f]];
    
    [self.firstButton setTintColor:[UIColor SHBlue]];
    [self.secondButton setTintColor:[UIColor SHBlue]];
    [self.thirdButton setTintColor:[UIColor SHBlue]];
    
    [self.imageButton setTitle:nil forState:UIControlStateNormal];
    
    [self.imageButton addTarget:self action:@selector(imageButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.firstButton addTarget:self action:@selector(firstButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.secondButton addTarget:self action:@selector(secondButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.thirdButton addTarget:self action:@selector(thirdButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) configureWithDelegate:(id)d
{
    [self setDelegate:d];
    [self.delegate setProfileImageViewFromCell:self.imageView];
    [self.delegate setEmailLabelFromCell:self.thirdButton];
    
    [self.imageView loadInImageWithRemoteURL:[[[LXSession thisSession] user] avatarURLString] localURL:nil];
    
    if ([[[LXSession thisSession] user] name] && [[[[LXSession thisSession] user] name] length] > 0) {
        [self.firstButton setTitle:[[[LXSession thisSession] user] name] forState:UIControlStateNormal];
    } else {
        [self.firstButton setTitle:@"+ Your Name" forState:UIControlStateNormal];
    }
    
    [self.secondButton setTitle:[[[LXSession thisSession] user] phone] forState:UIControlStateNormal];
    [self.secondButton setEnabled:NO];
    
    if ([[[LXSession thisSession] user] email] && [[[[LXSession thisSession] user] email] length] > 0) {
        [self.thirdButton setTitle:[NSString stringWithFormat:@"%@ (tap to change)",[[[LXSession thisSession] user] email]] forState:UIControlStateNormal];
        [self.thirdButton setEnabled:YES];
    } else {
        [self.thirdButton setTitle:@"+ Add Email" forState:UIControlStateNormal];
        [self.thirdButton setEnabled:YES];
    }
}

- (void) imageButtonAction:(UIButton*)sender
{
    [(SHProfileViewController*)[self delegate] action:@"changeImage"];
}

- (void) firstButtonAction:(UIButton*)sender
{
    [(SHProfileViewController*)[self delegate] action:@"changeName"];
}

- (void) secondButtonAction:(UIButton*)sender
{
    [(SHProfileViewController*)[self delegate] action:@"changePhone"];
}

- (void) thirdButtonAction:(UIButton*)sender
{
    [(SHProfileViewController*)[self delegate] action:@"changeEmail"];
}

@end
