//
//  SHSlackThoughtsViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextViewController.h"

@interface SHSlackThoughtsViewController : SLKTextViewController <UIScrollViewDelegate>
{
    NSInteger page;
}

@property (strong, nonatomic) NSString* localKey;
@property (nonatomic) BOOL shouldReload;

- (void) tryToReload;

@end
