//
//  LXBucket.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LXBucket)

- (void) refreshFromServerWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

+ (NSString*) allThoughtsLocalKey;

- (NSArray*) items;

- (NSMutableDictionary*) itemAtIndex:(NSInteger)index;

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index;

@end
