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
    [imageView setClipsToBounds:YES];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView.layer setCornerRadius:8.0f];
    
    [SGImageCache getImageForURL:mediaUrl thenDo:^(UIImage* image) {
        if (image) {
            imageView.image = image;
        }
    }];
}

@end
