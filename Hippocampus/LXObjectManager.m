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
    runningQueries = NO;
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
    if ([self.queries count] > 0 && !runningQueries) {
        runningQueries = YES;
        NSMutableDictionary* query = [self.queries firstObject];
        
        NSMutableDictionary* obj = [LXObjectManager objectWithLocalKey:[query objectForKey:@"local_key"]];
        if ((!obj && ![query objectForKey:@"object"]) || ![query objectForKey:@"path"] || ![query objectForKey:@"method"]) {
            [self removeQuery:query];
            [self saveQueries];
            [self runQueries];
        } else {
            [[LXServer shared] requestPath:[query objectForKey:@"path"] withMethod:[query objectForKey:@"method"] withParamaters:(obj ? [obj parameterReady] : [query objectForKey:@"object"]) authType:nil
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
    } else {
        runningQueries = NO;
    }
    [self saveQueries];
}

- (void) addQuery:(NSString*)path withMethod:(NSString*)method withLocalKey:(NSString*)localKey withObject:(NSDictionary*)object
{
    NSMutableDictionary* dictOfCalls = [[NSMutableDictionary alloc] init];
    if (path) {
        [dictOfCalls setObject:path forKey:@"path"];
    } else if (method) {
        [dictOfCalls setObject:method forKey:@"method"];
    } else if (localKey) {
        [dictOfCalls setObject:localKey forKey:@"local_key"];
    } else if (object) {
        [dictOfCalls setObject:object forKey:@"object"];
    }
    if (dictOfCalls) {
        [self.queries addObject:dictOfCalls];
        NSLog(@"QUERIES: %@", self.queries);
        [self runQueries];
    }
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
                               
                               dispatch_queue_t backgroundQueue = dispatch_queue_create("com.busproductions.queuecopy32", 0);
                               dispatch_async(backgroundQueue, ^{
                                   BOOL shouldRefresh = NO;
                                   
                                   for (NSDictionary* object in responseObject) {
                                       shouldRefresh = [[object mutableCopy] assignLocalVersionIfNeeded] || shouldRefresh;
                                       [self assignRefreshDate:[object updatedAt] forObjectTypes:pluralObjectType];
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
    
    NSArray* copyOfKeys = [[[[LXObjectManager defaultManager] library] allKeys] copy];
    NSMutableDictionary* copyOfDictionary = [[[LXObjectManager defaultManager] library] copy];
    
    for (NSString* key in copyOfKeys) {
        if ([[[LXObjectManager defaultManager] library] objectForKey:key]) {
            [[NSUserDefaults standardUserDefaults] setObject:([[copyOfDictionary objectForKey:key] respondsToSelector:@selector(cleanDictionary)] ? [[copyOfDictionary objectForKey:key] cleanDictionary] : [copyOfDictionary objectForKey:key]) forKey:key];
            //NSLog(@"object: %@", [copyOfDictionary objectForKey:key]);
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[UIApplication sharedApplication] endBackgroundTask:bgt];
}


@end
