//
//  LXBucket.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LXBucket)

+ (NSString*) allThoughtsLocalKey;

+ (void) bucketKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (void) refreshFromServerWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index;

- (void) removeItemFromBucket:(NSMutableDictionary*)item;


- (NSMutableArray*) items;
- (NSMutableArray*) itemKeys;
- (NSString*) cachedItemMessage;

- (NSMutableDictionary*) itemAtIndex:(NSInteger)index;

@end
