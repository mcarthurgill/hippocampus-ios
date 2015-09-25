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

@implementation SHBucketTableViewCell

@synthesize bucketLocalKey;
@synthesize card;
@synthesize collaboratorImages;
@synthesize bucketName;
@synthesize bucketItemMessage;
@synthesize collaborativeView;
@synthesize collaborativeViewHeightConstraint;



- (void)awakeFromNib
{
    [self setupAppearanceSettings];
    
    self.collaboratorImages = [[NSMutableArray alloc] init];
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
    
}

- (void) configureCollaborativeView
{
    for (UIView* v in self.collaboratorImages) {
        [v setHidden:YES];
    }
    //NSLog(@"%@", [self bucket]);
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


@end
