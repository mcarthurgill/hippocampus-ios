//
//  LXObjectManager.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXObjectManager : NSObject
{
    BOOL runningQueries;
}

+ (LXObjectManager*) defaultManager;
@property (strong, nonatomic) NSMutableDictionary* library;
@property (strong, nonatomic) NSMutableArray* queries;

- (void) runQueries;
- (void) addQuery:(NSString*)path withMethod:(NSString*)method withLocalKey:(NSString*)localKey withObject:(NSDictionary*)object;

- (void) refreshObjectTypes:(NSString*)pluralObjectType withAboveUpdatedAt:(NSString*)updatedAtString success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;
- (void) refreshObjectWithKey:(NSString*)localKey success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

// getting

+ (id) objectWithLocalKey:(NSString*)key;
+ (void) storeLocal:(id)object WithLocalKey:(NSString*)key;
+ (void) removeLocalWithKey:(NSString*)key;
+ (void) assignLocal:(id)object WithLocalKey:(NSString*)key alsoToDisk:(BOOL)toDisk;
+ (void) saveToDisk;

@end
