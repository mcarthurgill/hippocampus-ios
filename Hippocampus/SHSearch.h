//
//  SHSearch.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/28/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHSearch : NSObject

+ (SHSearch*) defaultManager;

@property (strong, nonatomic) NSMutableDictionary* cachedItems;
@property (strong, nonatomic) NSMutableDictionary* cachedBuckets;

- (NSMutableArray*) getCachedObjects:(NSString*)type withTerm:(NSString*)term;
- (NSString*) getCachedResultsTermWithType:(NSString*)type withTerm:(NSString*)term;

- (void) searchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) remoteSearchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) localBucketSearchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
