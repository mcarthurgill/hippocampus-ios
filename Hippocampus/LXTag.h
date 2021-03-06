//
//  LXTag.h
//  Hippocampus
//
//  Created by Will Schreiber on 10/29/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LXTag)

+ (BOOL) userHasTags;

- (NSString*) tagName;
- (NSArray*) bucketKeys;

+ (void) tagKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
