//
//  LXObjects.m
//  Stock
//
//  Created by Will Schreiber on 4/3/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXObjects.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation NSMutableDictionary (Extensions)


# pragma mark object properties


+ (NSMutableDictionary*) create:(NSString*)oT
{
    return [[NSMutableDictionary alloc] initWithDictionary:@{@"object_type":oT, @"local_id":[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]}];
}


- (NSString*) ID
{
    return [self objectForKey:@"id"];
}

- (NSString*) stringID
{
    return [NSString stringWithFormat:@"%@", [self objectForKey:@"id"]];
}

- (NSString*) deviceTimestamp
{
    return [self objectForKey:@"device_timestamp"];
}

- (NSString*) createdAt
{
    if ([self objectForKey:@"created_at_server"])
        return [self objectForKey:@"created_at_server"];
    return [self objectForKey:@"created_at"];
}

- (NSString*) updatedAt
{
    if ([self objectForKey:@"updated_at_server"])
        return [self objectForKey:@"updated_at_server"];
    return [self objectForKey:@"updated_at"];
}

- (NSString*) objectType
{
    return [self objectForKey:@"object_type"];
}

- (NSString*) pluralObjectType
{
    return [NSString stringWithFormat:@"%@%@", [self objectType], @"s"];
}

- (BOOL) isUser
{
    return [[self objectType] isEqualToString:@"user"];
}




- (BOOL) updatedMoreRecentThan:(NSMutableDictionary*)otherObject
{
    if (!otherObject || ![otherObject updatedAt])
        return YES;
    return [self updatedAt] > [otherObject updatedAt];
}




- (NSString*) authTypeForRequest
{
    if ([[self objectType] isEqualToString:@"user"] && ![self ID]) { //creating a new user
        return @"none";
    }
    return @"none";
}

- (NSString*) localKey
{
    return [NSString stringWithFormat:@"%@-%@-%@", [self objectType], ([self deviceTimestamp] ? [self deviceTimestamp] : @""), ([self isUser] ? @"" : [[[LXSession thisSession] user] ID])];
}

- (NSString*) requestPath
{
    return [self ID] ? [self objectPath] : [self rootPath];
}

- (NSString*) requestMethod
{
    return [self ID] ? @"PUT" : @"POST";
}

- (NSString*) rootPath
{
    return [NSString stringWithFormat:@"/%@.json", [self pluralObjectType]];
}

- (NSString*) objectPath
{
    return [NSString stringWithFormat:@"/%@/%@.json", [self pluralObjectType], [self ID]];
}

- (NSDictionary*) parameterReady
{
    return @{[self objectType]:self};
}


# pragma mark saving and syncing

- (void) sync
{
    [self saveBoth:nil failure:nil];
}

- (void) saveBoth:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback
{
    //save remote
    [self saveRemote:^(id responseObject) {
                    //save local
                    [self saveLocal:successCallback failure:failureCallback];
                    if (successCallback) {
                        successCallback(responseObject);
                    }
                }
                failure:^(NSError* error) {
                    if (failureCallback) {
                        failureCallback(error);
                    }
                }
     ];
}

- (void) saveLocal
{
    [self saveLocal:nil failure:nil];
}

- (void) saveLocal:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    if ([self updatedMoreRecentThan:[LXObjectManager objectWithLocalKey:[self localKey]]]) {
        [self saveLocalWithKey:[self localKey] success:successCallback failure:failureCallback];
    }
}

- (void) saveLocalWithKey:(NSString*)key
{
    [self saveLocalWithKey:key success:nil failure:nil];
}

- (void) saveLocalWithKey:(NSString*)key success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[NSUserDefaults standardUserDefaults] setObject:self forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[[LXObjectManager defaultManager] library] setObject:self forKey:key];
    if (successCallback) {
        successCallback(@{});
    }
}

- (void) saveRemote
{
    [self saveRemote:nil failure:nil];
}

- (void) saveRemote:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //SEND TO SERVER
    [[LXServer shared] requestPath:[self requestPath] withMethod:[self requestMethod] withParamaters:[self parameterReady] authType:[self authTypeForRequest]
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError* error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) destroyBoth
{
    [self destroyBoth:nil failure:nil];
}

- (void) destroyBoth:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //destroy remote
    [self destroyRemote:^(id responseObject) {
                    //destroy local
                    [self destroyLocal:successCallback failure:failureCallback];
                }
                failure:^(NSError* error) {
                }
     ];
}

- (void) destroyLocal
{
    [self destroyLocal:nil failure:nil];
}

- (void) destroyLocal:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //REMOVE FROM DISK
    [self destroyLocalWithKey:[self localKey] success:successCallback failure:failureCallback];
}

- (void) destroyLocalWithKey:(NSString*)key
{
    [self destroyLocalWithKey:key success:nil failure:nil];
}

- (void) destroyLocalWithKey:(NSString*)key success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[[LXObjectManager defaultManager] library] removeObjectForKey:[self localKey]];
    if (successCallback) {
        successCallback(@{});
    }
}

- (void) destroyRemote
{
    [self destroyRemote:nil failure:nil];
}

- (void) destroyRemote:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //DESTROY ON SERVER
    [[LXServer shared] requestPath:[self requestPath] withMethod:@"DELETE" withParamaters:[self parameterReady] authType:[self authTypeForRequest]
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError* error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}


- (BOOL) updateLocalVersionIfNeeded
{
    NSMutableDictionary* updateWith = [self mutableCopy];
    NSMutableDictionary* oldCopy = [LXObjectManager objectWithLocalKey:[updateWith localKey]];
    if (!oldCopy) {
        [[NSUserDefaults standardUserDefaults] setObject:[updateWith cleanDictionary] forKey:[updateWith localKey]];
        [[[LXObjectManager defaultManager] library] setObject:[updateWith cleanDictionary] forKey:[updateWith localKey]];
        return YES;
    } else if (![updateWith createdAt] || ( [updateWith updatedAt] > [oldCopy updatedAt] ) ) {
        for (NSString* key in [updateWith allKeys]) {
            [oldCopy setObject:[updateWith objectForKey:key] forKey:key];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[oldCopy cleanDictionary] forKey:[oldCopy localKey]];
        [[[LXObjectManager defaultManager] library] setObject:[oldCopy cleanDictionary] forKey:[oldCopy localKey]];
        return YES;
    }
    return NO;
}


@end