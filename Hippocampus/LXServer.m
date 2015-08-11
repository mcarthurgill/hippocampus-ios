//
//  LXServer.m
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXServer.h"
#import "LXAppDelegate.h"
#import "NSString+SHAEncryption.h"

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

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self requestPath:path withMethod:method withParamaters:params authType:nil constructingBodyWithBlock:nil success:successCallback failure:failureCallback];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)params constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self requestPath:path withMethod:method withParamaters:params authType:nil constructingBodyWithBlock:block success:successCallback failure:failureCallback];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params authType:authType success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self requestPath:path withMethod:method withParamaters:params authType:authType constructingBodyWithBlock:nil success:successCallback failure:failureCallback];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)p authType:(NSString*)authType constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
    }];
    
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithDictionary:p];
    if ([[LXSession thisSession] user]) {
        [params setObject:@{ @"uid":[[[LXSession thisSession] user] ID], @"token":[NSString userAuthToken] } forKey:@"auth"];
    }
    
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

+ (BOOL) errorBecauseOfBadConnection:(NSInteger)code
{
    for (NSNumber* testAgainst in @[@-999,@-1000,@-1001,@-1002,@-1003,@-1004,@-1005,@-1006,@-1007,@-1008,@-1009,@-1011,@-1018,@-1019,@-1020,@-1100,@-1102]) {
        if ([testAgainst integerValue] == code) {
            return YES;
        }
    }
    return NO;
}




# pragma mark specific callbacks

- (void) getAllBucketsWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/grouped_buckets.json", [[[LXSession thisSession] user] ID]] withMethod:@"GET" withParamaters: nil
                           success:^(id responseObject) {
                               //NSLog(@"allBuckets: %@", responseObject);
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   NSMutableDictionary* bucketsDictionary = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                                   if (bucketsDictionary) {
                                       //[[NSUserDefaults standardUserDefaults] setObject:[self bucketToSave:bucketsDictionary] forKey:@"buckets"];
                                       [[NSUserDefaults standardUserDefaults] setObject:[bucketsDictionary cleanDictionary] forKey:@"buckets"];
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
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@.json", [[[LXSession thisSession] user] ID]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"page"] && [[responseObject objectForKey:@"page"] integerValue] == 0) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       NSMutableArray* saveArray = [NSMutableArray arrayWithArray:[responseObject objectForKey:@"items"]];
                                       [saveArray addObjectsFromArray:[responseObject objectForKey:@"outstanding_items"]];
                                       [[NSUserDefaults standardUserDefaults] setObject:[self itemsToSave:saveArray] forKey:@"0"];
                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                       
                                       //[[[LXSession thisSession] user] setUserStats:responseObject];
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

- (void) getBucketInfoWithPage:(int)p bucketID:(NSString*)bucketID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/info.json", bucketID] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
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
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/media_urls.json", bucketID] withMethod:@"GET" withParamaters:@{@"user_id": [[[LXSession thisSession] user] ID]}
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

- (void) getItemsNearCenterX:(CGFloat)centerX andCenterY:(CGFloat)centerY andDX:(CGFloat)dx andDY:(CGFloat)dy success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/items/within_bounds.json" withMethod:@"GET" withParamaters: @{ @"user_id": [[[LXSession thisSession] user] ID], @"centerx": [NSString stringWithFormat:@"%f", centerX], @"centery": [NSString stringWithFormat:@"%f", centerY], @"dx": [NSString stringWithFormat:@"%f", dx], @"dy": [NSString stringWithFormat:@"%f", dy] }
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

- (void) getItemsNearCurrentLocation:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback
{
    CLLocation *loc = [LXSession currentLocation];
    [[LXServer shared] requestPath:@"/items/near_location.json" withMethod:@"GET" withParamaters: @{ @"user_id": [[[LXSession thisSession] user] ID], @"latitude": [NSString stringWithFormat:@"%f", loc.coordinate.latitude], @"longitude": [NSString stringWithFormat:@"%f", loc.coordinate.longitude] }
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
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/reminders.json", [[[LXSession thisSession] user] ID]] withMethod:@"GET" withParamaters: @{ @"page":[NSString stringWithFormat:@"%d", p]}
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
    [[LXServer shared] requestPath:@"/items/random.json" withMethod:@"GET" withParamaters: @{ @"user_id": [[[LXSession thisSession] user] ID], @"limit": [NSString stringWithFormat:@"%d", limit]}
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
    [[LXServer shared] requestPath:@"/search.json" withMethod:@"GET" withParamaters: @{ @"t" : term, @"user_id" : [[[LXSession thisSession] user] ID] }
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


- (void) createBucketWithFirstName:(NSString*)firstName andBucketType:(NSString*)bucketType success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"buckets.json" withMethod:@"POST"
                    withParamaters:@{@"bucket" : @{@"first_name": firstName, @"user_id": [[[LXSession thisSession] user] ID], @"bucket_type": bucketType } }
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

- (void) createBucketWithFirstName:(NSString*)firstName andGroupID:(NSString*)groupID success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"buckets.json" withMethod:@"POST"
                    withParamaters:@{@"bucket" : @{@"first_name": firstName, @"user_id": [[[LXSession thisSession] user] ID] }, @"group_id":groupID }
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


- (void) updateUser:(NSDictionary*)params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@.json", [[[LXSession thisSession] user] ID]] withMethod:@"PUT" withParamaters:params
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

- (void) createContactCardWithBucket:(NSDictionary*)bucket andContact:(NSMutableDictionary*)contact success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback {
    NSError *error;
    
    UIImage *img = (UIImage*)[contact objectForKey:@"image"];
    NSString* path = [[LXSession thisSession] writeImageToDocumentsFolder:img];
    [contact removeObjectForKey:@"image"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:contact options:NSJSONWritingPrettyPrinted error:&error];
    NSString* jsonContact = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [[LXServer shared] requestPath:@"/contact_cards.json" withMethod:@"POST" withParamaters:@{@"contact_card":@{@"bucket_id":[bucket ID], @"contact_info":jsonContact}}
         constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
             if (img) {
                 [formData appendPartWithFileData:[NSData dataWithContentsOfFile:path] name:@"file" fileName:@"image.jpg" mimeType:@"image/jpeg"];
             }
         }
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

- (void) deleteContactCard:(NSMutableDictionary*)contact success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback {
    
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/contact_cards/%@.json", [contact ID]] withMethod:@"DELETE" withParamaters:nil
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

- (void) removeItem:(NSDictionary*)item fromBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
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

- (void) updateDeviceToken:(NSData *)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSString *tokenString = [[token description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[LXServer shared] requestPath:@"/device_tokens" withMethod:@"POST" withParamaters:@{@"device_token": @{@"ios_device_token": tokenString, @"environment": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ENVIRONMENT"], @"user_id": [[[LXSession thisSession] user] ID]}} success:^(id responseObject) {
                                if (successCallback) {
                                    successCallback(responseObject);
                                }
                           } failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}



- (void) createBucketUserPairsWithContacts:(NSMutableArray*)contacts andBucket:(NSDictionary*)bucket success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/add_collaborators.json", [bucket ID]] withMethod:@"POST" withParamaters:@{@"contacts" : contacts}
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

- (void) deleteBucketUserPairWithBucketID:(NSString*)bucketID andPhoneNumber:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/remove_collaborators.json", bucketID] withMethod:@"POST" withParamaters:@{@"phone": phone}
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

- (void) getSetupQuestionsForPercentage:(NSString *)percentage success:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback
{
    percentage = percentage ? percentage : @"25";
    [[LXServer shared] requestPath:@"/setup_questions.json" withMethod:@"GET" withParamaters:@{@"percentage": percentage}
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

- (void) submitResponseToSetupQuestion:(NSString*)response success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/create_from_setup_questions.json" withMethod:@"POST" withParamaters:@{@"setup_question": @{@"question": [[LXSetup theSetup] currentQuestion], @"response": response}}
                           success:^(id responseObject) {
                               if (successCallback) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^(void){
                                       [self getAllItemsWithPage:0 success:nil failure:nil];
                                   });
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


//int codes[] = {
//    //kCFURLErrorUnknown,     //-998
//    kCFURLErrorCancelled,   //-999
//    kCFURLErrorBadURL,      //-1000
//    kCFURLErrorTimedOut,    //-1001
//    kCFURLErrorUnsupportedURL, //-1002
//    kCFURLErrorCannotFindHost, //-1003
//    kCFURLErrorCannotConnectToHost,     //-1004
//    kCFURLErrorNetworkConnectionLost,   //-1005
//    kCFURLErrorDNSLookupFailed,         //-1006
//    kCFURLErrorHTTPTooManyRedirects,    //-1007
//    kCFURLErrorResourceUnavailable,     //-1008
//    kCFURLErrorNotConnectedToInternet,  //-1009
//    //kCFURLErrorRedirectToNonExistentLocation,   //-1010
//    kCFURLErrorBadServerResponse,               //-1011
//    //kCFURLErrorUserCancelledAuthentication,     //-1012
//    //kCFURLErrorUserAuthenticationRequired,      //-1013
//    //kCFURLErrorZeroByteResource,        //-1014
//    //kCFURLErrorCannotDecodeRawData,     //-1015
//    //kCFURLErrorCannotDecodeContentData, //-1016
//    //kCFURLErrorCannotParseResponse,     //-1017
//    kCFURLErrorInternationalRoamingOff, //-1018
//    kCFURLErrorCallIsActive,                //-1019
//    kCFURLErrorDataNotAllowed,              //-1020
//    //kCFURLErrorRequestBodyStreamExhausted,  //-1021
//    kCFURLErrorFileDoesNotExist,            //-1100
//    //kCFURLErrorFileIsDirectory,             //-1101
//    kCFURLErrorNoPermissionsToReadFile,     //-1102
//    //kCFURLErrorDataLengthExceedsMaximum,     //-1103
//};