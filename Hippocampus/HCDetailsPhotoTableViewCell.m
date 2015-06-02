//
//  HCDetailsPhotoTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCDetailsPhotoTableViewCell.h"

@implementation HCDetailsPhotoTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithMediaUrl:(NSString*)mediaUrl andImageView:(UIImageView*)imageView {

    mediaUrl = [mediaUrl croppedImageURLToScreenWidth];
    NSLog(@"mediaURL: %@", mediaUrl);
    
    [imageView setClipsToBounds:YES];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView.layer setCornerRadius:4.0f];
    
    if (![SGImageCache haveImageForURL:mediaUrl] || ![imageView.image isEqual:[SGImageCache imageForURL:mediaUrl]]) {
        imageView.image = nil;
        [imageView setAlpha:0.0f];
        [SGImageCache getImageForURL:mediaUrl].then(^(UIImage* image) {
            if (image) {
                imageView.image = image;
                [UIView animateWithDuration:0.4f animations:^(void){
                    [imageView setAlpha:1.0f];
                }];
            }
        });
    }
}

@end
