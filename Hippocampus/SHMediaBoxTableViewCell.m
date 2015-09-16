//
//  SHMediaBoxTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHMediaBoxTableViewCell.h"
#import "SHItemViewController.h"

#define IMAGE_FADE_IN_TIME 0.4f

@implementation SHMediaBoxTableViewCell

@synthesize delegate;
@synthesize localKey;
@synthesize medium;
@synthesize imageView;
@synthesize activityIndicator;
@synthesize imageViewHeightConstraint;
@synthesize imageViewWidthConstraint;
@synthesize longPress;

- (void)awakeFromNib
{
    [self.imageView setBackgroundColor:[UIColor SHLightGray]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.imageView.layer.cornerRadius = 4.0f;
    [self.imageView setClipsToBounds:YES];
    
    [self.imageView.layer setBorderWidth:1.0f];
    [self.imageView.layer setBorderColor:[UIColor SHLightGray].CGColor];
    
    [self.activityIndicator removeFromSuperview];
    [self.imageView addSubview:self.activityIndicator];
    
    [self setupGestureRecognizers];
}

- (void) setupGestureRecognizers
{
    if (!self.longPress) {
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        //[self.imageView addGestureRecognizer:longPress];
        [self addGestureRecognizer:longPress];
    }
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

- (void) configureWithLocalKey:(NSString*)key medium:(NSDictionary*)m
{
    [self setLocalKey:key];
    [self setMedium:m];
    
    [self.activityIndicator startAnimating];
    
    [self.imageView loadInImageWithRemoteURL:[medium mediaThumbnailURLWithScreenWidth] localURL:[medium objectForKey:@"local_file_path"]];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    //self.imageViewWidthConstraint.constant = self.bounds.size.width;
    self.imageViewHeightConstraint.constant = [medium heightForWidth:self.imageView.bounds.size.width];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}





# pragma mark actions

- (IBAction)longPressAction:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan){
        [(SHItemViewController*)delegate longPressWithObject:[self.medium mutableCopy] type:@"media"];
    }
}

@end
