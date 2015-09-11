//
//  SHMediaBoxTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHMediaBoxTableViewCell.h"

#define IMAGE_FADE_IN_TIME 0.4f

@implementation SHMediaBoxTableViewCell

@synthesize localKey;
@synthesize imageView;
@synthesize activityIndicator;
@synthesize imageViewHeightConstraint;
@synthesize imageViewWidthConstraint;

- (void)awakeFromNib
{
    [self.imageView setBackgroundColor:[UIColor SHLightGray]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
    
    self.imageView.layer.cornerRadius = 4.0f;
    [self.imageView setClipsToBounds:YES];
    
    [self.imageView.layer setBorderWidth:1.0f];
    [self.imageView.layer setBorderColor:[UIColor SHLightGray].CGColor];
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

- (void) configureWithLocalKey:(NSString*)key medium:(NSDictionary*)medium
{
    [self setLocalKey:key];
    
    [self.activityIndicator startAnimating];
    
    if ([SGImageCache haveImageForURL:[medium mediaThumbnailURLWithScreenWidth]]) {
        self.imageView.image = [SGImageCache imageForURL:[medium mediaThumbnailURLWithScreenWidth]];
        [self.imageView setAlpha:1.0f];
        self.activityIndicator.alpha = 0.0;
        [self.activityIndicator removeFromSuperview];
    } else if (![self.imageView.image isEqual:[SGImageCache imageForURL:[medium mediaThumbnailURLWithScreenWidth]]]) {
        self.imageView.image = nil;
        [self.imageView setAlpha:1.0f];
        [SGImageCache getImageForURL:[medium mediaThumbnailURLWithScreenWidth]].then(^(UIImage* image) {
            if (image) {
                float curAlpha = [self.imageView alpha];
                [self.imageView setAlpha:0.0f];
                self.imageView.image = image;
                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void){
                    [self.imageView setAlpha:curAlpha];
                    self.activityIndicator.alpha = 0.0;
                    [self.activityIndicator removeFromSuperview];
                }];
            }
        });
    }
    
    //self.imageViewWidthConstraint.constant = self.bounds.size.width;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    //self.imageViewWidthConstraint.constant = self.bounds.size.width;
    self.imageViewHeightConstraint.constant = [medium heightForWidth:self.imageView.bounds.size.width];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
