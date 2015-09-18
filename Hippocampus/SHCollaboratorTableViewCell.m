//
//  SHCollaboratorTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHCollaboratorTableViewCell.h"

@implementation SHCollaboratorTableViewCell

@synthesize localKey;
@synthesize delegate;
@synthesize collaborator;

@synthesize imageView;
@synthesize label;

- (void)awakeFromNib
{
    [self.imageView.layer setCornerRadius:16.0f];
    [self.imageView setClipsToBounds:YES];
    
    [self.label setFont:[UIFont titleFontWithSize:14.0f]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void) configureWithLocalKey:(NSString*)lk delegate:(id)d collaborator:(NSDictionary*)c
{
    [self setLocalKey:lk];
    [self setDelegate:d];
    [self setCollaborator:c];
    
    if (self.collaborator) {
        [self setupForUser];
    } else {
        [self setupForAdd];
    }
}

- (void) setupForUser
{
    [self.imageView setBackgroundColor:[UIColor SHLighterGray]];
    [self.imageView loadInImageWithRemoteURL:[self.collaborator avatarURLStringFromPhone] localURL:nil];
    
    [self.label setTextColor:[UIColor SHFontDarkGray]];
    NSMutableAttributedString* nameString;
    if ([[self.collaborator objectForKey:@"phone_number"] isEqualToString:[[[LXSession thisSession] user] phone]] && ![[self.collaborator name] isEqualToString:@"You"]) {
        //this user
        nameString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (You)", [self.collaborator name]]];
        [nameString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:[nameString.string rangeOfString:@"(You)"]];
    } else {
        nameString = [[NSMutableAttributedString alloc] initWithString:[self.collaborator name]];
    }
    [self.label setAttributedText:nameString];
}

- (void) setupForAdd
{
    [self.imageView setBackgroundColor:[UIColor clearColor]];
    [self.imageView setImage:[UIImage imageNamed:@"add_new.png"]];
    
    [self.label setText:@"Add Collaborator"];
    [self.label setTextColor:[UIColor SHGreen]];
}

@end
