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
    NSMutableDictionary* temp = [[NSMutableDictionary alloc] initWithDictionary:@{@"object_type":oT, @"device_timestamp":[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]}];
    [temp setObject:[temp localKey] forKey:@"local_key"];
    [temp setObject:[[[LXSession thisSession] user] ID] forKey:@"user_id"];
    return temp;
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
    if ([[self objectType] isEqualToString:@"medium"])
        return @"media";
    return [NSString stringWithFormat:@"%@%@", [self objectType], @"s"];
}

- (BOOL) isUser
{
    return [[self objectType] isEqualToString:@"user"];
}




- (BOOL) updatedMoreRecentThan:(NSMutableDictionary*)otherObject
{
    if (!otherObject || ![otherObject updatedAt] || ![self updatedAt])
        return YES;
    return [self updatedAt] >= [otherObject updatedAt];
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
    if ([self objectForKey:@"local_key"] && NULL_TO_NIL([self objectForKey:@"local_key"]))
        return [self objectForKey:@"local_key"];
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

- (void) saveRemote
{
    [self saveRemote:nil failure:nil];
}

- (void) delaySaveRemote
{
    [[LXObjectManager defaultManager] addQuery:[self requestPath] withMethod:[self requestMethod] withLocalKey:[self localKey] withObject:nil];
}

- (void) saveRemote:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    if ([[self objectType] isEqualToString:@"item"] && [self hasUnsavedMedia]) {
        //SEND TO SERVER WITH MEDIA
        [[LXServer shared] requestPath:[self requestPath] withMethod:[self requestMethod] withParamaters:[self parameterReady] authType:[self authTypeForRequest]
             constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
                 NSInteger i = 0;
                 for (NSMutableDictionary* medium in [self media]) {
                     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                     NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[medium objectForKey:@"local_file_name"]];
                     NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
                     [formData appendPartWithFileData:data name:[NSString stringWithFormat:@"media[]"] fileName:[medium localKey] mimeType:@"image/jpeg"];
                     ++i;
                 }
             } success:^(id responseObject) {
                 for (NSMutableDictionary* medium in [self media]) {
                     NSFileManager *fileManager = [NSFileManager defaultManager];
                     NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                     NSString *filePath = [documentsPath stringByAppendingPathComponent:[medium objectForKey:@"local_file_name"]];
                     NSError *error;
                     [fileManager removeItemAtPath:filePath error:&error];
                 }
                 //SAVE LOCALLY
                 [[responseObject mutableCopy] assignLocalVersionIfNeeded:YES];
                 if (successCallback) {
                     successCallback(responseObject);
                 }
             } failure:^(NSError* error) {
                 if (failureCallback) {
                     failureCallback(error);
                 }
             }
         ];
    } else {
        //SEND TO SERVER
        [[LXServer shared] requestPath:[self requestPath] withMethod:[self requestMethod] withParamaters:[self parameterReady] authType:[self authTypeForRequest]
                               success:^(id responseObject) {
                                   //SAVE LOCALLY
                                   [[responseObject mutableCopy] assignLocalVersionIfNeeded:YES];
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
}

- (void) destroyRemote
{
    [self destroyRemote:nil failure:nil];
}

- (void) destroyRemote:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //DESTROY ON SERVER
    if ([self status]) {
        [self setObject:@"deleted" forKey:@"status"];
    }
    [[LXServer shared] requestPath:[self requestPath] withMethod:@"DELETE" withParamaters:@{@"local_key":[self localKey]} authType:[self authTypeForRequest]
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


- (BOOL) assignLocalVersionIfNeeded:(BOOL)alsoSaveToDisk
{
    NSMutableDictionary* updateWith = [self mutableCopy];
    NSMutableDictionary* oldCopy = [LXObjectManager objectWithLocalKey:[updateWith localKey]];
    if (!oldCopy) {
        [updateWith assignLocalWithKey:[updateWith localKey] alsoSaveToDisk:alsoSaveToDisk];
        return YES;
    } else {
        for (NSString* key in [updateWith allKeys]) {
            [oldCopy setObject:[updateWith objectForKey:key] forKey:key];
        }
        [oldCopy assignLocalWithKey:[oldCopy localKey] alsoSaveToDisk:alsoSaveToDisk];
        return YES;
    }
}

- (void) assignLocalWithKey:(NSString*)key alsoSaveToDisk:(BOOL)alsoSaveToDisk
{
    if ([self updatedMoreRecentThan:[LXObjectManager objectWithLocalKey:[self localKey]]]) {
        [LXObjectManager assignLocal:self WithLocalKey:key alsoToDisk:alsoSaveToDisk];
    }
}


@end
