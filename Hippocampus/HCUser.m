//
//  HCUser.m
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCUser.h"
#import "LXAppDelegate.h"

@implementation HCUser

@dynamic loggedInUser;
@dynamic userID;
@dynamic phone;
@dynamic countryCode;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic lastItemUpdateTime;
@dynamic lastBucketUpdateTime;

+ (NSMutableDictionary *)resourceKeysForPropertyKeys
{
    return [[NSMutableDictionary alloc] initWithDictionary:@{
                                                             @"userID": @"id",
                                                             @"createdAt": @"created_at",
                                                             @"updatedAt": @"updated_at",
                                                             @"countryCode": @"country_code",
                                                             @"phone": @"phone"
                                                             }];
}

# pragma  mark logged in user

+ (HCUser*) loggedInUser
{
    NSManagedObjectContext *moc = [[LXSession thisSession] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"HCUser" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(loggedInUser == %@)", [NSNumber numberWithBool:YES]];
    
    [request setPredicate:predicate];
    NSError* error;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (array.count==0) {
        //NO OBJECT FOUND
        NSLog(@"NO LOGGED IN USER FOUND");
        return nil;
    } else {
        NSLog(@"RETURNING LOGGED IN USER");
        return [array objectAtIndex:0];
    }
    return nil;
}

+ (void) loginUser:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/users.json" withMethod:@"POST" withParamaters:@{ @"user" : @{@"phone": phone, @"country_code" : @"1"}}
                           success:^(id responseObject) {
                               HCUser* user = [LXServer addToDatabase:@"HCUser" object:responseObject primaryKeyName:@"userID" withMapping:[HCUser resourceKeysForPropertyKeys]];
                               [user makeLoggedInUser];
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

- (void) makeLoggedInUser
{
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"loggedInUser"];
    [[self managedObjectContext] save:nil];
    [[LXSession thisSession] setUser:self];
}


# pragma mark retrievals

- (void) getNewItemsSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self getItems:[[[LXSession thisSession] user] lastItemUpdateTime] success:successCallback failure:failureCallback];
}

- (void) getItems:(NSNumber*)lastUpdated success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/items.json", self.userID] withMethod:@"GET" withParamaters:@{@"above": [NSString stringWithFormat:@"%f", lastUpdated.floatValue]}
                           success:^(id responseObject) {
                               [LXServer addArrayToDatabase:@"HCItem" array:(NSArray*)responseObject primaryKeyName:@"itemID" withMapping:[HCItem resourceKeysForPropertyKeys]];
                               if (successCallback)
                                   successCallback(responseObject);
                           }
                           failure:^(NSError *error) {
                               if (failureCallback)
                                   failureCallback(error);
                           }
     ];
}

- (void) getNewBucketsSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self getBuckets:[[[LXSession thisSession] user] lastBucketUpdateTime] success:successCallback failure:failureCallback];
}

- (void) getBuckets:(NSNumber*)lastUpdated success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@/buckets.json", self.userID] withMethod:@"GET" withParamaters:@{@"above": [NSString stringWithFormat:@"%f", lastUpdated.floatValue]}
                           success:^(id responseObject) {
                               [LXServer addArrayToDatabase:@"HCBucket" array:(NSArray*)responseObject primaryKeyName:@"bucketID" withMapping:[HCBucket resourceKeysForPropertyKeys]];
                               if (successCallback)
                                   successCallback(responseObject);
                           }
                           failure:^(NSError *error) {
                               if (failureCallback)
                                   failureCallback(error);
                           }
     ];
}

@end
