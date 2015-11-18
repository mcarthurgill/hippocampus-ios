//
//  LXTag.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/29/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "LXTag.h"

@implementation NSMutableDictionary (LXTag)

+ (BOOL) userHasTags
{
    return [LXObjectManager objectWithLocalKey:@"tagLocalKeys"] && [[LXObjectManager objectWithLocalKey:@"tagLocalKeys"] respondsToSelector:@selector(count)] && [[LXObjectManager objectWithLocalKey:@"tagLocalKeys"] count] > 0;
}

- (NSString*) tagName
{
    return [self objectForKey:@"tag_name"] && NULL_TO_NIL([self objectForKey:@"tag_name"]) ? [self objectForKey:@"tag_name"] : @"";
}

- (NSArray*) bucketKeys
{
    return [self objectForKey:@"bucket_keys"] && NULL_TO_NIL([self objectForKey:@"bucket_keys"]) ? [self objectForKey:@"bucket_keys"] : @[];
}

+ (void) tagKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/tags/keys" withMethod:@"GET" withParamaters:nil authType:@"user"
                           success:^(id responseObject){
                               if ([responseObject respondsToSelector:@selector(count)]) {
                                   [LXObjectManager assignLocal:responseObject WithLocalKey:@"tagLocalKeys" alsoToDisk:YES];
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedTagLocalKeys" object:nil userInfo:nil];
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

@end
