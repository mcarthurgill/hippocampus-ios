//
//  LXItem.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LXItem)

+ (NSMutableDictionary*) createItemWithMessage:(NSString*)message;

- (void) destroyItem;

- (BOOL) hasMedia;
- (NSMutableArray*) media;

@end
