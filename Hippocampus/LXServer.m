//
//  LXServer.m
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXServer.h"
#import "LXAppDelegate.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation LXServer

+ (LXServer*) shared
{
    static LXServer* sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL* baseURL = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"APIRoot"]];
        NSLog(@"%@", [baseURL absoluteString]);
        sharedClient = [[LXServer alloc] initWithBaseURL:baseURL];
        sharedClient.responseSerializer = [AFJSONResponseSerializer serializer];
    });
    return sharedClient;
}

+ (id) getObjectFromModel:(NSString*)modelName primaryKeyName:(NSString*)primaryKeyName primaryKey:(NSString*)primaryKey
{
    NSManagedObjectContext *moc = [[LXSession thisSession] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:modelName inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(%@ == %@)", primaryKeyName, primaryKey]];
    
    [request setPredicate:predicate];
    NSError* error;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (array.count==0) {
        //NO OBJECT FOUND
        NSLog(@"NO %@ FOUND", modelName);
        return nil;
    } else {
        NSLog(@"RETURNING A %@, out of %lu total.", modelName, (unsigned long)array.count);
        return [array objectAtIndex:0];
    }
    return nil;
}

+ (id) addToDatabase:(NSString *)modelName object:(NSDictionary *)object primaryKeyName:(NSString *)primaryKeyName withMapping:(NSDictionary *)mapping
{
    
    //NSLog(@"object: %@", object);
    
    if (!NULL_TO_NIL([object valueForKey:@"id"])) {
        return nil;
    }
    
    NSString* object_id = [NSString stringWithFormat:@"%@",[object valueForKey:@"id"]];
    
    id newObject = [LXServer getObjectFromModel:modelName primaryKeyName:primaryKeyName primaryKey:object_id];
    
    NSManagedObjectContext *moc = [[LXSession thisSession] managedObjectContext];
    
    NSLog(@"newObject: %@", newObject);
    
    if (!newObject) {
        newObject = [NSEntityDescription
                   insertNewObjectForEntityForName:modelName
                   inManagedObjectContext:moc];
    }
    
    NSArray* keys = [mapping allKeys];
    for (int i = 0; i < keys.count; ++i) {
        NSString* core_key = keys[i];
        NSString* json_key = [mapping objectForKey:core_key];
        if (NULL_TO_NIL([object valueForKey:json_key])) {
            [newObject setValue:[NSString stringWithFormat:@"%@",[object valueForKey:json_key]] forKey:core_key];
        }
    }
    
    if ([modelName isEqualToString:@"HCBucket"]) {
        [newObject setValue:[newObject titleString] forKey:@"name"];
    }
    
    if ([newObject createdAt] && [[newObject createdAt] length] > 0) {
        NSLog(@"lastCreatedAt: %f", [[NSDate timeWithString:[newObject createdAt]] timeIntervalSince1970]);
        if ([modelName isEqualToString:@"HCItem"]) {
            //update last item update
            if ([[NSDate timeWithString:[newObject createdAt]] timeIntervalSince1970] > [[[[LXSession thisSession] user] lastItemUpdateTime] doubleValue]) {
                [[[LXSession thisSession] user] setLastItemUpdateTime:[NSNumber numberWithFloat:[[NSDate timeWithString:[newObject createdAt]] timeIntervalSince1970]] ];
            }
        } else if ([modelName isEqualToString:@"HCBucket"]) {
            //update last bucket update
            if ([[NSDate timeWithString:[newObject createdAt]] timeIntervalSince1970] > [[[[LXSession thisSession] user] lastBucketUpdateTime] doubleValue]) {
                [[[LXSession thisSession] user] setLastBucketUpdateTime:[NSNumber numberWithFloat:[[NSDate timeWithString:[newObject createdAt]] timeIntervalSince1970]] ];
            }
        }
    }
    
    [[[LXSession thisSession] managedObjectContext] save:nil];
    
    return newObject;
}

+ (void) addArrayToDatabase:(NSString*)modelName array:(NSArray*)array primaryKeyName:(NSString *)primaryKey withMapping:(NSDictionary *)mapping
{
    for (int i = 0; i < array.count; ++i) {
        [LXServer addToDatabase:modelName object:[array objectAtIndex:i] primaryKeyName:primaryKey withMapping:mapping];
    }
    [[[LXSession thisSession] managedObjectContext] save:nil];
}

+ (void) saveObject:(id)object withPath:(NSString*)path method:(NSString*)method mapping:(NSDictionary*)mapping success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] init];
    NSArray* keys = [mapping allKeys];
    NSLog(@"Keys: %@", mapping);
    for (int i = 0; i < keys.count; ++i) {
        NSString* core_key = keys[i];
        NSString* json_key = [mapping objectForKey:core_key];
        if ([object valueForKey:core_key] && ![core_key isEqualToString:@"createdAt"] && ![core_key isEqualToString:@"updatedAt"] && ![core_key isEqualToString:@"id"]) {
            [parameters setValue:[object valueForKey:core_key] forKey:json_key];
        }
    }
    NSDictionary* finalParameters = [[NSDictionary alloc] initWithObjectsAndKeys:parameters, [object serverObjectName], nil];
    NSLog(@"finalParameters: %@", finalParameters);
    [[LXServer shared] requestPath:path withMethod:method withParamaters:finalParameters
                           success:^(id responseObject) {
                               if (successCallback)
                                   successCallback(responseObject);
                           }
                           failure:^(NSError *error) {
                               if (failureCallback)
                                   failureCallback(error);
                           }
     ];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self requestPath:path withMethod:method withParamaters:params constructingBodyWithBlock:nil success:successCallback failure:failureCallback];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)params constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
    }];
    if ([method.uppercaseString isEqualToString:@"GET"]) {
        [self GET:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            //NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        }];
    } else if ([method.uppercaseString isEqualToString:@"POST"]) {
        [self POST:path parameters:params constructingBodyWithBlock:block success:^(NSURLSessionDataTask* task, id responseObject) {
            //NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        }];
    } else if ([method.uppercaseString isEqualToString:@"PUT"]) {
        [self PUT:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            //NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        }];
    } else if ([method.uppercaseString isEqualToString:@"DELETE"]) {
        [self DELETE:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            //NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        }];
    }
}





# pragma mark specific callbacks
- (void) getAllBucketsWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/buckets.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: nil
                           success:^(id responseObject) {
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   NSMutableDictionary* bucketsDictionary = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                                   if (bucketsDictionary) {
                                       [[NSUserDefaults standardUserDefaults] setObject:[self bucketToSave:bucketsDictionary] forKey:@"buckets"];
                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                       [(LXAppDelegate *)[[UIApplication sharedApplication] delegate] setBadgeIcon];
                                   }
                               });
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) getBucketShowWithPage:(int)p bucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", bucketID] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"page"] && [[responseObject objectForKey:@"page"] integerValue] == 0) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       [[NSUserDefaults standardUserDefaults] setObject:[self itemsToSave:[responseObject objectForKey:@"items"]] forKey:[NSString stringWithFormat:@"%li",(long)[bucketID integerValue]]];
                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                   });
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) getAllItemsWithPage:(int)p success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"page"] && [[responseObject objectForKey:@"page"] integerValue] == 0) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       NSMutableArray* saveArray = [NSMutableArray arrayWithArray:[responseObject objectForKey:@"items"]];
                                       [saveArray addObjectsFromArray:[responseObject objectForKey:@"outstanding_items"]];
                                       [[NSUserDefaults standardUserDefaults] setObject:[self itemsToSave:saveArray] forKey:@"0"];
                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                   });
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) savebucketWithBucketID:(NSString*)bucketID andBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", bucketID] withMethod:@"PUT" withParamaters: @{ @"bucket":bucket}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) getMediaUrlsForBucketID:(NSString *)bucketID success:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/media_urls.json", bucketID] withMethod:@"GET" withParamaters:@{@"user_id": [[HCUser loggedInUser] userID]}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) deleteBucketWithBucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@.json", bucketID] withMethod:@"DELETE" withParamaters:nil
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) getNotesNearCurrentLocation:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    CLLocationCoordinate2D loc = [LXSession currentLocation].coordinate;
    [[LXServer shared] requestPath:@"/items/near_location.json" withMethod:@"GET" withParamaters: @{ @"user_id": [[HCUser loggedInUser] userID], @"latitude": [NSString stringWithFormat:@"%f", loc.latitude], @"longitude": [NSString stringWithFormat:@"%f", loc.longitude] }
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) getUpcomingRemindersWithPage:(int)p success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/reminders.json", [[HCUser loggedInUser] userID]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) getRandomItemsWithLimit:(int)limit success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/items/random.json" withMethod:@"GET" withParamaters: @{ @"user_id": [[HCUser loggedInUser] userID], @"limit": [NSString stringWithFormat:@"%d", limit]}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];

}

- (void) getSearchResults:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/search.json" withMethod:@"GET" withParamaters: @{ @"t" : term, @"user_id" : [[HCUser loggedInUser] userID] }
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


- (void) createBucketWithFirstName:(NSString*)firstName andBucketType:(NSString*)bucketType success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback {
    [[LXServer shared] requestPath:@"buckets.json" withMethod:@"POST"
                    withParamaters:@{@"bucket" : @{@"first_name": firstName, @"user_id": [[[LXSession thisSession] user] userID], @"bucket_type": bucketType } }
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


- (void) saveReminderForItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [item ID]] withMethod:@"PUT" withParamaters:@{@"item":item}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) saveUpdatedMessageForItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [item ID]] withMethod:@"PUT" withParamaters:@{@"item":item}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];

}


- (void) updateItemInfoWithItem:(NSDictionary*)item success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/items/%@.json", [item ID]] withMethod:@"GET" withParamaters:nil
                           success:^(id responseObject){
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}


- (void) addItem:(NSDictionary*)item toBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback {
    [[LXServer shared] requestPath:@"/bucket_item_pairs.json" withMethod:@"POST" withParamaters:@{@"bucket_item_pair":@{@"bucket_id":[bucket ID], @"item_id":[item ID]}}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}


- (void) removeItem:(NSDictionary*)item fromBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback {
    [[LXServer shared] requestPath:@"/destroy_with_bucket_and_item.json" withMethod:@"DELETE" withParamaters:@{@"bucket_id":[bucket ID], @"item_id":[item ID]}
                           success:^(id responseObject){
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) updateDeviceToken:(NSData *)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback {
    NSString *tokenString = [[token description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[LXServer shared] requestPath:@"/device_tokens" withMethod:@"POST" withParamaters:@{@"device_token": @{@"ios_device_token": tokenString, @"environment": @"production", @"user_id": [[HCUser loggedInUser] userID]}}
                           success:^(id responseObject){
                                if (successCallback) {
                                    successCallback(responseObject);
                                }
                           }
                           failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
];
}

- (NSMutableDictionary*) bucketToSave:(NSMutableDictionary*)incomingDictionary
{
    NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
    
    NSArray* keys = [incomingDictionary allKeys];
    for (NSString* k in keys) {
        NSMutableArray* cur = [incomingDictionary objectForKey:k];
        NSMutableArray* new = [[NSMutableArray alloc] init];
        for (NSDictionary* t in cur) {
            NSMutableDictionary* tDict = [[NSMutableDictionary alloc] initWithDictionary:t];
            NSArray* keys = [tDict allKeys];
            for (NSString* k in keys) {
                if (!NULL_TO_NIL([tDict objectForKey:k])) {
                    [tDict removeObjectForKey:k];
                }
            }
            [new addObject:tDict];
        }
        [temp setObject:new forKey:k];
    }
    
    return temp;
}

- (NSMutableArray*) itemsToSave:(NSArray*)items
{
    NSMutableArray* temp = [[NSMutableArray alloc] init];
    for (NSDictionary* t in items) {
        [temp addObject:[t cleanDictionary]];
    }
    return temp;
}



@end
