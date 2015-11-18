//
//  UIImageView+Addons.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/15/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Addons)

@property (strong, nonatomic) NSString *remoteURLString;

- (void) loadInImageWithRemoteURL:(NSString*)remoteURL localURL:(NSString*)localURL;
- (void) drawImageAsync:(UIImage*)image;

@end
