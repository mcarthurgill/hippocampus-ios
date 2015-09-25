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
    NSLog(@"failed-queries: %@", [LXObjectManager objectWithLocalKey:@"failed-queries"]);
    if ([LXObjectManager objectWithLocalKey:@"failed-queries"] && [[LXObjectManager objectWithLocalKey:@"failed-queries"] count] > 0) {
        [self.queries addObjectsFromArray:[LXObjectManager objectWithLocalKey:@"failed-queries"]];
        NSLog(@"failed-queries-array: %@", self.queries);
    }
}

- (void) runQueries
{
    if ([self.queries count] > 0 && !runningQueries) {
        runningQueries = YES;
        NSMutableDictionary* query = [self.queries firstObject];
        
        NSMutableDictionary* obj = [query objectForKey:@"object"] ? [[query objectForKey:@"object"] mutableCopy] : ([LXObjectManager objectWithLocalKey:[query objectForKey:@"local_key"]] ? [[[LXObjectManager objectWithLocalKey:[query objectForKey:@"local_key"] ] parameterReady] mutableCopy] : nil);
        if (!obj || ![query objectForKey:@"path"] || ![query objectForKey:@"method"]) {
            [self removeQuery:query];
            [self saveQueries];
            [self runQueries];
        } else {
            if ([obj objectForKey:@"item"] && [[obj objectForKey:@"item"] hasUnsavedMedia]) {
                //SEND TO SERVER WITH MEDIA
                [[LXServer shared] requestPath:[query objectForKey:@"path"] withMethod:[query objectForKey:@"method"] withParamaters:obj authType:@"repeat"
                     constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
                         NSInteger i = 0;
                         for (NSMutableDictionary* medium in [[obj objectForKey:@"item"] media]) {
                             NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                             NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[medium objectForKey:@"local_file_name"]];
                             NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
                             NSLog(@"file path: %@", [medium objectForKey:@"local_file_name"]);
                             if (data) {
                                 [formData appendPartWithFileData:data name:[NSString stringWithFormat:@"media[]"] fileName:[medium localKey] mimeType:@"image/jpeg"];
                             }
                             ++i;
                         }
                     } success:^(id responseObject) {
                         for (NSMutableDictionary* medium in [[obj objectForKey:@"item"] media]) {
                             NSFileManager *fileManager = [NSFileManager defaultManager];
                             NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                             NSString *filePath = [documentsPath stringByAppendingPathComponent:[medium objectForKey:@"local_file_name"]];
                             NSError *error;
                             [fileManager removeItemAtPath:filePath error:&error];
                         }
                         //SAVE LOCALLY
                         [[NSNotificationCenter defaultCenter] postNotificationName:@"successfulQueryDelayed" object:nil userInfo:@{@"query":query}];//,@"responseObject":responseObject
                         [self removeQuery:query];
                         [self saveQueries];
                         runningQueries = NO;
                         [self runQueries];
                     } failure:^(NSError* error) {
                         NSLog(@"CODE=%ld", (long)error.code);
                         if (![LXServer errorBecauseOfBadConnection:error.code]) {
                             [self removeQuery:query];
                             [self saveQueries];
                             runningQueries = NO;
                             [self runQueries];
                         }
                     }
                 ];
            } else {
                [[LXServer shared] requestPath:[query objectForKey:@"path"] withMethod:[query objectForKey:@"method"] withParamaters:obj authType:@"repeat"
                                       success:^(id responseObject){
                                           [[NSNotificationCenter defaultCenter] postNotificationName:@"successfulQueryDelayed" object:nil userInfo:@{@"query":query}];//,@"responseObject":responseObject
                                           [self removeQuery:query];
                                           [self saveQueries];
                                           runningQueries = NO;
                                           [self runQueries];
                                       }
                                       failure:^(NSError* error){
                                           NSLog(@"CODE=%ld", (long)error.code);
                                           if (![LXServer errorBecauseOfBadConnection:error.code]) {
                                               [self removeQuery:query];
                                               [self saveQueries];
                                               runningQueries = NO;
                                               [self runQueries];
                                           }
                                       }
                 ];
            }
        }
    } else if ([self.queries count] == 0) {
        runningQueries = NO;
    }
    [self saveQueries];
}

- (void) addQuery:(NSString*)path withMethod:(NSString*)method withLocalKey:(NSString*)localKey withObject:(NSDictionary*)object
{
    NSMutableDictionary* dictOfCalls = [[NSMutableDictionary alloc] init];
    if (path) {
        [dictOfCalls setObject:path forKey:@"path"];
    }
    if (method) {
        [dictOfCalls setObject:method forKey:@"method"];
    }
    if (localKey) {
        [dictOfCalls setObject:localKey forKey:@"local_key"];
    }
    if (object) {
        [dictOfCalls setObject:object forKey:@"object"];
    }
    if (dictOfCalls) {
        [self.queries addObject:dictOfCalls];
        NSLog(@"QUERIES: %@", self.queries);
        [LXObjectManager assignLocal:self.queries WithLocalKey:@"failed-queries" alsoToDisk:YES];
        [self runQueries];
    }
}

- (void) removeQuery:(id)query
{
    [self.queries removeObject:query];
}

- (void) saveQueries
{
    [LXObjectManager assignLocal:self.queries WithLocalKey:@"failed-queries" alsoToDisk:YES];
}

- (void) refreshObjectTypes:(NSString*)pluralObjectType withAboveUpdatedAt:(NSString*)updatedAtString success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/%@/changes", pluralObjectType] withMethod:@"GET" withParamaters:@{@"updated_at_timestamp":(updatedAtString ? updatedAtString : ([LXObjectManager objectWithLocalKey:[NSString stringWithFormat:@"%@-lastUpdatedAt", pluralObjectType]] ? [NSString stringWithFormat:@"%f",[[NSDate timeWithString:[LXObjectManager objectWithLocalKey:[NSString stringWithFormat:@"%@-lastUpdatedAt", pluralObjectType]]] timeIntervalSince1970]] : @"0"))}
                           success:^(id responseObject){
                               
                               dispatch_queue_t backgroundQueue = dispatch_queue_create("com.busproductions.queuecopy32", 0);
                               dispatch_async(backgroundQueue, ^{
                                   BOOL shouldRefresh = NO;
                                   
                                   for (NSDictionary* object in responseObject) {
                                       shouldRefresh = [[object mutableCopy] assignLocalVersionIfNeeded:YES] || shouldRefresh;
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
                               if ([[responseObject mutableCopy] assignLocalVersionIfNeeded:YES]) {
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
        [LXObjectManager assignLocal:updatedAt WithLocalKey:[NSString stringWithFormat:@"%@-lastUpdatedAt", pluralObjectType] alsoToDisk:NO];
    }
}



# pragma mark getting

+ (id) objectWithLocalKey:(NSString*)key
{
    //NSLog(@"getting object With Key: %@", key);
    if (key && key.length > 0 && [LXObjectManager defaultManager] && [[LXObjectManager defaultManager] library]) {
        if ([[[LXObjectManager defaultManager] library] objectForKey:key]) {
            return [[[LXObjectManager defaultManager] library] objectForKey:key];
        } else {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:key];
            id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            if (obj) {
                [[[LXObjectManager defaultManager] library] setObject:([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSMutableDictionary class]] ? [obj cleanDictionary] : [obj mutableCopy]) forKey:key];
                return [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            }
        }
    }
    return nil;
}

+ (void) assignLocal:(id)object WithLocalKey:(NSString*)key alsoToDisk:(BOOL)toDisk
{
    id mutableCopy = [object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSMutableDictionary class]] ? [object cleanDictionary] : [object mutableCopy];
    [[[LXObjectManager defaultManager] library] setObject:mutableCopy forKey:key];
    if (toDisk) {
        [self saveToDisk:mutableCopy WithLocalKey:key];
    }
}

+ (void) storeLocal:(id)object WithLocalKey:(NSString*)key
{
    [self assignLocal:object WithLocalKey:key alsoToDisk:NO];
    if ([self objectWithLocalKey:key]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:key];
        [NSKeyedArchiver archiveRootObject:[self objectWithLocalKey:key] toFile:filePath];
    }
}

+ (void) removeLocalWithKey:(NSString*)key
{
    //remove from singleton
    [[[LXObjectManager defaultManager] library] removeObjectForKey:key];
    
    //remove from disk
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:key];
    NSError *error;
    [fileManager removeItemAtPath:filePath error:&error];
}

+ (void) saveToDisk
{
    UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray* copyOfKeys = [[[[LXObjectManager defaultManager] library] allKeys] copy];
        NSMutableDictionary* copyOfDictionary = [[[LXObjectManager defaultManager] library] copy];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        for (NSString* key in copyOfKeys) {
            if ([copyOfDictionary objectForKey:key]) {
                NSString *filePath = [documentsDirectory stringByAppendingPathComponent:key];
                [NSKeyedArchiver archiveRootObject:([[copyOfDictionary objectForKey:key] respondsToSelector:@selector(cleanDictionary)] ? [[copyOfDictionary objectForKey:key] cleanDictionary] : [copyOfDictionary objectForKey:key]) toFile:filePath];
            }
        }
        [[UIApplication sharedApplication] endBackgroundTask:bgt];
    });
}

+ (void) saveToDisk:(id)object WithLocalKey:(NSString*)key
{
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.busproductions.savetodiskqueue", 0);
    dispatch_async(backgroundQueue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:key];
        [NSKeyedArchiver archiveRootObject:object toFile:filePath];
    });
}


@end
