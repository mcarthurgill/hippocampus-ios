//
//  LXObjectManager.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXObjectManager.h"

static LXObjectManager* defaultManager = nil;

@implementation LXObjectManager

@synthesize library;
@synthesize queries;


# pragma mark singleton resource

//constructor
-(id) init
{
    if (defaultManager) {
        return defaultManager;
    }
    self = [super init];
    return self;
}


//singleton instance
+ (LXObjectManager*) defaultManager
{
    if (!defaultManager) {
        defaultManager = [[super allocWithZone:NULL] init];
        [defaultManager setVariables];
    }
    return defaultManager;
}


//prevent creation of additional instances
+ (id) allocWithZone:(NSZone *)zone
{
    return [self defaultManager];
}


//set singleton variables
- (void) setVariables
{
    self.library = [[NSMutableDictionary alloc] init];
    self.queries = [[NSMutableArray alloc] init];
    [self initializeWithFailedQueries];
}


# pragma mark server interface

- (void) initializeWithFailedQueries
{
    NSLog(@"failed-queries: %@", [[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"]);
    if ([[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"] && [[[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"] count] > 0) {
        [self.queries addObjectsFromArray:[[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"]];
        NSLog(@"failed-queries-array: %@", self.queries);
    }
}

- (void) runQueries
{
    if ([self.queries count] > 0) {
        NSArray* query = [self.queries firstObject];
        [[LXServer shared] requestPath:query[0] withMethod:query[1] withParamaters:query[2] authType:query[3]
                               success:^(id responseObject){
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"successfulQueryDelayed" object:nil userInfo:@{@"query":query}];//,@"responseObject":responseObject
                                   [self removeQuery:query];
                                   [self saveQueries];
                                   [self runQueries];
                               }
                               failure:^(NSError* error){
                                   NSLog(@"CODE=%ld", (long)error.code);
                                   if (![LXServer errorBecauseOfBadConnection:error.code]) {
                                       [self removeQuery:query];
                                       [self saveQueries];
                                       [self runQueries];
                                   }
                               }
         ];
    }
    [self saveQueries];
}

- (void) addQuery:(NSString*)path withMethod:(NSString*)method withObject:(NSDictionary*)object withAuthType:(NSString*)authType
{
    [self.queries addObject:@[path, method, object, authType]];
    [self runQueries];
}

- (void) removeQuery:(id)query
{
    [self.queries removeObject:query];
}

- (void) saveQueries
{
    if ([self.queries count] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.queries forKey:@"failed-queries"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"failed-queries"];
    }
}

- (void) refreshObjectTypes:(NSString*)pluralObjectType withAboveUpdatedAt:(NSString*)updatedAtString success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/%@/changes", pluralObjectType] withMethod:@"GET" withParamaters:@{@"updated_at_timestamp":(updatedAtString ? updatedAtString : ([LXObjectManager objectWithLocalKey:[NSString stringWithFormat:@"%@-lastUpdatedAt", pluralObjectType]] ? [NSString stringWithFormat:@"%f",[[NSDate timeWithString:[LXObjectManager objectWithLocalKey:[NSString stringWithFormat:@"%@-lastUpdatedAt", pluralObjectType]]] timeIntervalSince1970]] : @"0"))}
                           success:^(id responseObject){
                               
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   BOOL shouldRefresh = NO;
                                   
                                   for (NSDictionary* object in responseObject) {
                                       shouldRefresh = [[object mutableCopy] assignLocalVersionIfNeeded] || shouldRefresh;
                                       [self assignRefreshDate:[object updatedAt] forObjectTypes:pluralObjectType];
                                   }
                                   if (shouldRefresh) {
                                       //[[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":bucket}];
                                   }
                               });
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError* error){
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) refreshObjectWithKey:(NSString*)localKey success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //UNTESTED
    //parse the local key
    NSMutableDictionary* tempObject = [@{@"object_type":[localKey objectTypeFromLocalKey], @"device_timestamp":[localKey deviceTimestampFromLocalKey], @"user_id":[localKey userIDFromLocalKey], @"local_key":localKey} mutableCopy];
    //setup query
    [[LXServer shared] requestPath:@"/key" withMethod:@"GET" withParamaters:tempObject authType:@"user"
                           success:^(id responseObject) {
                               //update on disk
                               if ([[responseObject mutableCopy] assignLocalVersionIfNeeded]) {
                                   //notify system of change
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshedObject" object:nil userInfo:responseObject];
                               }
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

- (void) assignRefreshDate:(NSString*)updatedAt forObjectTypes:(NSString*)pluralObjectType
{
    NSString* currentDate = [LXObjectManager objectWithLocalKey:[NSString stringWithFormat:@"%@-lastUpdatedAt", pluralObjectType]];
    //NSLog(@"%@|%@", currentDate, updatedAt);
    if (!currentDate || currentDate < updatedAt) {
        [LXObjectManager assignLocal:updatedAt WithLocalKey:[NSString stringWithFormat:@"%@-lastUpdatedAt", pluralObjectType]];
    }
}



# pragma mark getting

+ (id) objectWithLocalKey:(NSString*)key
{
    if (key && key.length > 0) {
        if ([[[LXObjectManager defaultManager] library] objectForKey:key]) {
            return [[[LXObjectManager defaultManager] library] objectForKey:key];
        } else if ([[NSUserDefaults standardUserDefaults] objectForKey:key]) {
            [[[LXObjectManager defaultManager] library] setObject:[[[NSUserDefaults standardUserDefaults] objectForKey:key] mutableCopy] forKey:key];
            return [[[LXObjectManager defaultManager] library] objectForKey:key];
        } else {
            //[[LXObjectManager defaultManager] refreshObjectWithKey:key success:nil failure:nil];
            //theoretically, go refresh object in question.
        }
    }
    return nil;
}

+ (void) assignLocal:(id)object WithLocalKey:(NSString*)key
{
    id mutableCopy = [object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSMutableDictionary class]] ? [object cleanDictionary] : [object mutableCopy];
    [[[LXObjectManager defaultManager] library] setObject:mutableCopy forKey:key];
}

+ (void) saveToDisk
{
    UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
    }];
    
    for (NSString* key in [[[LXObjectManager defaultManager] library] allKeys]) {
        if ([[[LXObjectManager defaultManager] library] objectForKey:key]) {
            [[NSUserDefaults standardUserDefaults] setObject:([[[[LXObjectManager defaultManager] library] objectForKey:key] respondsToSelector:@selector(cleanDictionary)] ? [[[[LXObjectManager defaultManager] library] objectForKey:key] cleanDictionary] : [[[LXObjectManager defaultManager] library] objectForKey:key]) forKey:key];
            NSLog(@"object: %@", [[[LXObjectManager defaultManager] library] objectForKey:key]);
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[UIApplication sharedApplication] endBackgroundTask:bgt];
}


@end
