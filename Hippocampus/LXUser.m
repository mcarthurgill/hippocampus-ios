//
//  LXUser.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXUser.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation NSMutableDictionary (User)

- (void) makeLoggedInUser
{
    [LXObjectManager storeLocal:self WithLocalKey:[self localKey]];
    [LXObjectManager storeLocal:[self localKey] WithLocalKey:@"localUserKey"];
}

- (void) logout
{
    [LXObjectManager removeLocalWithKey:[self localKey]];
    [LXObjectManager removeLocalWithKey:@"localUserKey"];
    
    UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
    }];
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[LXObjectManager defaultManager] library] && [[[LXObjectManager defaultManager] library] allKeys]) {
            NSArray* copyOfKeys = [[[[LXObjectManager defaultManager] library] allKeys] copy];
            NSMutableDictionary* copyOfDictionary = [[[LXObjectManager defaultManager] library] copy];
            for (NSString* key in copyOfKeys) {
                if ([copyOfDictionary objectForKey:key]) {
                    [LXObjectManager removeLocalWithKey:key];
                }
            }
        }
        [[UIApplication sharedApplication] endBackgroundTask:bgt];
    //});
}

- (void) updateTimeZone
{
    NSLog(@"timeZone: %@", [[NSTimeZone localTimeZone] name]);
    [self saveRemoteWithNewAttributes:@{@"time_zone":[[NSTimeZone localTimeZone] name]} success:nil failure:nil];
}


- (NSString*) email
{
    if (NULL_TO_NIL([self objectForKey:@"email"]))
        return [self objectForKey:@"email"];
    return nil;
}

- (NSString*) phone
{
    if (NULL_TO_NIL([self objectForKey:@"phone"]))
        return [self objectForKey:@"phone"];
    return nil;
}

- (NSString*) salt
{
    if (NULL_TO_NIL([self objectForKey:@"salt"]))
        return [self objectForKey:@"salt"];
    return nil;
}

- (NSNumber*) score
{
    if (NULL_TO_NIL([self objectForKey:@"score"]))
        return [self objectForKey:@"score"];
    return nil;
}

- (NSNumber*) numberItems
{
    if (NULL_TO_NIL([self objectForKey:@"number_items"]))
        return [self objectForKey:@"number_items"];
    return nil;
}

- (NSNumber*) numberBuckets
{
    if (NULL_TO_NIL([self objectForKey:@"number_buckets"]))
        return [self objectForKey:@"number_buckets"];
    return [NSNumber numberWithInt:0];
}

- (NSNumber*) numberBucketsAllowed
{
    //NSLog(@"number_allowed: %@", [self objectForKey:@"number_buckets_allowed"]);
    if (NULL_TO_NIL([self objectForKey:@"number_buckets_allowed"]))
        return [self objectForKey:@"number_buckets_allowed"];
    return nil;
}

- (BOOL) overNumberBucketsAllowed
{
    //NSLog(@"OVER: %d", [[self numberBuckets] integerValue] > [[self numberBucketsAllowed] integerValue]);
    return [self numberBucketsAllowed] && [[self numberBuckets] integerValue] > [[self numberBucketsAllowed] integerValue];
}

- (NSNumber*) setupCompletion
{
    if (NULL_TO_NIL([self objectForKey:@"setupCompletion"]))
        return [self objectForKey:@"setupCompletion"];
    return nil;
}

- (BOOL) completedSetup
{
    return [self.setupCompletion integerValue] == 100;
}

- (void) updateProfilePictureWithImage:(UIImage*)image
{
    [SGImageCache flushImagesOlderThan:[[[NSDate alloc] init] timeIntervalSinceNow]];
    
    NSMutableDictionary* medium = [NSMutableDictionary create:@"medium"];
    [medium setObject:[NSNumber numberWithFloat:image.size.width] forKey:@"width"];
    [medium setObject:[NSNumber numberWithFloat:image.size.height] forKey:@"height"];
    
    [[LXServer shared] requestPath:@"/media/avatar.json" withMethod:@"POST" withParamaters:@{@"medium":medium}
         constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
             NSData *data = UIImageJPEGRepresentation(image, 0.8);
             [formData appendPartWithFileData:data name:[NSString stringWithFormat:@"file"] fileName:[self localKey] mimeType:@"image/jpeg"];
         } success:^(id responseObject) {
             //SAVE LOCALLY
             [SGImageCache flushImagesOlderThan:[[[NSDate alloc] init] timeIntervalSinceNow]];
             [[responseObject mutableCopy] assignLocalVersionIfNeeded:YES];
         } failure:^(NSError* error) {
         }
     ];
}

- (void) changeName:(NSString *)newName
{
    [self saveRemoteWithNewAttributes:@{@"name":newName} success:nil failure:nil];
}

- (BOOL) hasMembership
{
    return [self membership] && [[self membership] length] > 0 && ![[self membership] isEqualToString:@"none"];
}

- (NSString*) membership
{
    return [self objectForKey:@"membership"] && NULL_TO_NIL([self objectForKey:@"membership"]) ? [self objectForKey:@"membership"] : nil;
}

- (void) updateToMembership:(NSString*)type success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self saveRemoteWithNewAttributes:@{@"membership":type} success:^(id responseObject) {
        if (successCallback) {
            successCallback(responseObject);
        }
    } failure:^(NSError* error) {
        if (failureCallback) {
            failureCallback(error);
        }
    }];
}

- (BOOL) shouldShowPaywall
{
    return ![[[LXSession thisSession] user] hasMembership] && [[[LXSession thisSession] user] overNumberBucketsAllowed];
}


# pragma mark - Nudges
- (void) nudgeKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/reminders", [[[LXSession thisSession] user] ID]] withMethod:@"GET" withParamaters:nil authType:@"user"
                           success:^(id responseObject){
                               if ([[responseObject objectForKey:@"reminders"] respondsToSelector:@selector(count)]) {
                                   [LXObjectManager assignLocal:[responseObject objectForKey:@"reminders"] WithLocalKey:@"nudgeLocalKeys" alsoToDisk:YES];
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedNudgeLocalKeys" object:nil userInfo:nil];
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           } failure:^(NSError* error){
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

+ (BOOL) userHasNudges
{
    return [LXObjectManager objectWithLocalKey:@"nudgeLocalKeys"] && [[LXObjectManager objectWithLocalKey:@"nudgeLocalKeys"] respondsToSelector:@selector(count)] && [[LXObjectManager objectWithLocalKey:@"nudgeLocalKeys"] count] > 0;
}
@end
