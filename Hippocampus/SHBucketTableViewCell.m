//
//  SHBucketTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHBucketTableViewCell.h"
@import QuartzCore;

#define COLLABORATOR_HEIGHT 48.0f
#define COLLABORATOR_IMAGE_HEIGHT 32.0f
#define TAG_HEIGHT 32.0f

@implementation SHBucketTableViewCell

@synthesize bucketLocalKey;
@synthesize card;
@synthesize collaboratorImages;
@synthesize bucketName;
@synthesize bucketItemMessage;

@synthesize collaborativeView;
@synthesize collaborativeViewHeightConstraint;

@synthesize tagsView;
@synthesize tagsViewHeightConstraint;
@synthesize tagButtons;
@synthesize tagButtonConstraints;



- (void)awakeFromNib
{
    [self setupAppearanceSettings];
    
    self.collaboratorImages = [[NSMutableArray alloc] init];
    self.tagButtons = [[NSMutableArray alloc] init];
}





# pragma mark setup

- (void) setupAppearanceSettings
{
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [card.layer setCornerRadius:4.0f];
    [card setClipsToBounds:YES];
    [card.layer setBorderColor:[UIColor SHLightGray].CGColor];
    [card.layer setBorderWidth:1.0f];
    
    CALayer *TopBorder = [CALayer layer];
    TopBorder.frame = CGRectMake(0.0f, 0.0f, self.contentView.bounds.size.width*3, 1.0f);
    TopBorder.backgroundColor = [UIColor SHLightGray].CGColor;
    [self.collaborativeView.layer addSublayer:TopBorder];

    [self.collaborativeView setBackgroundColor:[UIColor clearColor]];
    
    CALayer *TopBorder2 = [CALayer layer];
    TopBorder2.frame = CGRectMake(0.0f, 0.0f, self.contentView.bounds.size.width*3, 1.0f);
    TopBorder2.backgroundColor = [UIColor SHLightGray].CGColor;
    [self.tagsView.layer addSublayer:TopBorder2];
    
    [self.tagsView setBackgroundColor:[UIColor clearColor]];
    
    [bucketName setFont:[UIFont titleFontWithSize:16.0f]];
    
    [bucketItemMessage setFont:[UIFont titleFontWithSize:14.0f]];
    [bucketItemMessage setTextColor:[UIColor SHFontLightGray]];
    
    self.separatorInset = UIEdgeInsetsMake(0.f, self.bounds.size.width, 0.f, 0.0f);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
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

- (NSMutableDictionary*) bucket
{
    return [LXObjectManager objectWithLocalKey:self.bucketLocalKey];
}





# pragma mark configure

- (void) configureWithBucketLocalKey:(NSString*)key
{
    [self setBucketLocalKey:key];
    
    NSMutableDictionary* bucket = [LXObjectManager objectWithLocalKey:self.bucketLocalKey];
    
    NSMutableAttributedString* titleString;
    if ([bucket itemsCount]) {
        titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)", [bucket firstName], [bucket itemsCount]]];
        [titleString addAttribute:NSForegroundColorAttributeName value:[bucket bucketColor] range:NSMakeRange(0,[bucket firstName].length)];
        [titleString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange([bucket firstName].length,[titleString length]-[bucket firstName].length)];
    } else {
        titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [bucket firstName]]];
        [titleString addAttribute:NSForegroundColorAttributeName value:[bucket bucketColor] range:NSMakeRange(0,[bucket firstName].length)];
    }
    [bucketName setAttributedText:titleString];
    
    [bucketItemMessage setText:[[[bucket cachedItemMessage] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] stringByReplacingOccurrencesOfString:@"\n" withString:@" "]];
    [bucketItemMessage setLineBreakMode:NSLineBreakByTruncatingTail];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    [self configureCollaborativeView];
    
    [self configureTagsView];
    [self handleTagButtons];
}

- (void) configureCollaborativeView
{
    for (UIView* v in self.collaboratorImages) {
        [v setHidden:YES];
    }
    if ([[self bucket] isCollaborativeThread]) {
        self.collaborativeViewHeightConstraint.constant = COLLABORATOR_HEIGHT;
        [self.collaborativeView setHidden:NO];
        NSInteger index = 0;
        for (NSDictionary* collaborator in [[self bucket] objectForKey:@"bucket_user_pairs"]) {
            UIImageView* iv = [self imageViewForMediumAtIndex:index];
            [iv setHidden:NO];
            [iv loadInImageWithRemoteURL:[collaborator avatarURLStringFromPhone] localURL:nil];
            ++index;
        }
    } else {
        self.collaborativeViewHeightConstraint.constant = 0.0f;
        [self.collaborativeView setHidden:YES];
    }
}

- (void) configureTagsView
{
    //for (UIView* v in self.collaboratorImages) {
    //    [v setHidden:YES];
    //}
    if ([[self bucket] hasTags]) {
        self.tagsViewHeightConstraint.constant = COLLABORATOR_HEIGHT;
        [self.tagsView setHidden:NO];
//        NSInteger index = 0;
//        for (NSDictionary* tag in [[self bucket] tagsArray]) {
//            
//            ++index;
//        }
    } else {
        self.tagsViewHeightConstraint.constant = 0.0f;
        [self.tagsView setHidden:YES];
    }
}

- (UIImageView*) imageViewForMediumAtIndex:(NSInteger)index
{
    if (index < [self.collaboratorImages count])
        return [self.collaboratorImages objectAtIndex:index];
    
    UIImageView* iv = [[UIImageView alloc] init];
    
    [iv setContentMode:UIViewContentModeScaleAspectFill];
    [iv setClipsToBounds:YES];
    //[iv setTranslatesAutoresizingMaskIntoConstraints:NO];
    [iv setBackgroundColor:[UIColor SHLightGray]];
    
    iv.layer.cornerRadius = COLLABORATOR_IMAGE_HEIGHT/2.0;
    //[iv.layer setBorderWidth:1.0f];
    //[iv.layer setBorderColor:[UIColor SHLightGray].CGColor];
    
    [iv setFrame:CGRectMake(10+index*(COLLABORATOR_IMAGE_HEIGHT+5), (COLLABORATOR_HEIGHT-COLLABORATOR_IMAGE_HEIGHT)/2, COLLABORATOR_IMAGE_HEIGHT, COLLABORATOR_IMAGE_HEIGHT)];
    [self.collaborativeView addSubview:iv];
    
    [self.collaboratorImages addObject:iv];
    
    return iv;
}




# pragma mark tag buttons

- (void) handleTagButtons
{
    [self hideTagButtons];
    if ([self bucket] && [[self bucket] hasTags]) {
        [self createTagButtons];
    }
}

- (void) createTagButtons
{
    self.tagButtonConstraints = [[NSMutableArray alloc] init];
    
    NSInteger count = 0;
    for (NSMutableDictionary* tag in [[self bucket] tagsArray]) {
        if ([tag belongsToCurrentUser]) {
            UIButton* button = [self buttonForTag:tag atIndex:count];
            [button setTag:count];
            [button setHidden:NO];
        }
        ++count;
    }
    //[self layoutButtons];
}

- (UIButton*) buttonForTag:(NSMutableDictionary*)tag atIndex:(NSInteger)index
{
    //tag = [LXObjectManager objectWithLocalKey:[tag localKey]];
    
    UIButton* button = [self getBlankTagButtonAtIndex:index];
    
    [button setTitle:[NSString stringWithFormat:@"   %@   ", [tag tagName]] forState:UIControlStateNormal];
    
    return button;
}

- (UIButton*) getBlankTagButtonAtIndex:(NSInteger)index
{
    if (index < [self.tagButtons count])
        return [self.tagButtons objectAtIndex:index];
    
    UIButton* button = [[UIButton alloc] init];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [button setBackgroundColor:[UIColor slightBackgroundColor]];
    [[button titleLabel] setFont:[UIFont secondaryFontWithSize:13.0f]];
    [[button titleLabel] setTextColor:[UIColor SHFontDarkGray]];
    [button setTitleColor:[UIColor SHFontDarkGray] forState:UIControlStateNormal];
    [button.layer setCornerRadius:5];
    [button setClipsToBounds:YES];
    [button setShowsTouchWhenHighlighted:YES];
    [button.layer setBorderColor:[[UIColor SHGreen] colorWithAlphaComponent:0.2f].CGColor];
    [button.layer setBorderWidth:0.8f];
    
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.tagButtons addObject:button];
    [self.tagsView addSubview:button];
    
    [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:TAG_HEIGHT] toView:button];
    [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.tagsView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0] toView:self.tagsView];
    if (index == 0) {
        [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.tagsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10.0] toView:self.tagsView];
    } else {
        [self addButtonConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:[self.tagButtons objectAtIndex:(index-1)] attribute:NSLayoutAttributeRight multiplier:1.0 constant:10.0] toView:self.tagsView];
    }
    [button invalidateIntrinsicContentSize];
    
    return button;
}

- (void) hideTagButtons
{
    for (UIView* button in self.tagButtons) {
        [button setHidden:YES];
    }
    
    for (NSLayoutConstraint* constraint in self.tagButtonConstraints) {
        [self.contentView removeConstraint:constraint];
    }
    self.tagButtonConstraints = nil;
}

- (void) addButtonConstraint:(NSLayoutConstraint *)constraint toView:(UIView*)view
{
    [view addConstraint:constraint];
    [self.tagButtonConstraints addObject:constraint];
}



# pragma mark actions

- (void) buttonTapped:(UIButton*)sender
{
    
}

@end
