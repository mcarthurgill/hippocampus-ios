//
//  LXObjects.h
//  Stock
//
//  Created by Will Schreiber on 4/3/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Extensions)

+ (NSMutableDictionary*) create:(NSString*)oT;

- (NSString*) ID;
- (NSString*) stringID;
- (NSString*) deviceTimestamp;
- (NSString*) localKey;
- (NSString*) createdAt;
- (NSString*) updatedAt;
- (NSString*) objectType;
- (NSString*) pluralObjectType;

- (BOOL) updatedMoreRecentThan:(NSMutableDictionary*)otherObject;

- (NSString*) requestPath;
- (NSString*) requestMethod;
- (NSString*) rootPath;
- (NSString*) objectPath;
- (NSDictionary*) parameterReady;

// saving and syncing

- (void) saveRemote;
- (void) delaySaveRemote;
- (void) saveRemote:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (void) destroyRemote;
- (void) destroyRemote:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (BOOL) assignLocalVersionIfNeeded:(BOOL)alsoSaveToDisk;
- (void) assignLocalWithKey:(NSString*)key alsoSaveToDisk:(BOOL)alsoSaveToDisk;


@end
