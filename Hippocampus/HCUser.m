//
//  HCUser.m
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCUser.h"
#import "LXAppDelegate.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation HCUser

@dynamic loggedInUser;
@dynamic userID;
@dynamic phone;
@dynamic countryCode;
@dynamic numberBuckets;
@dynamic numberItems;
@dynamic score;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic lastItemUpdateTime;
@dynamic lastBucketUpdateTime;
@dynamic setupCompletion;

+ (NSMutableDictionary *)resourceKeysForPropertyKeys
{
    return [[NSMutableDictionary alloc] initWithDictionary:@{
                                                             @"userID": @"id",
                                                             @"numberBuckets": @"number_buckets",
                                                             @"numberItems": @"number_items",
                                                             @"score": @"score",
                                                             @"setupCompletion": @"setupCompletion",
                                                             @"createdAt": @"created_at",
                                                             @"createdAt": @"created_at",
                                                             @"updatedAt": @"updated_at",
                                                             @"countryCode": @"country_code",
                                                             @"phone": @"phone",
                                                             @"email": @"email",
                                                             @"salt": @"salt"
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

+ (void) loginUser:(NSString*)phone callingCode:(NSString*)callingCode success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/passcode.json" withMethod:@"POST" withParamaters:@{ @"phone": phone, @"calling_code" : callingCode}
                           success:^(id responseObject) {
                               //HCUser* user = [LXServer addToDatabase:@"HCUser" object:responseObject primaryKeyName:@"userID" withMapping:[HCUser resourceKeysForPropertyKeys]];
                               //[user makeLoggedInUser];
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

+ (void) tokenVerify:(NSString*)code phone:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/session.json" withMethod:@"POST" withParamaters:@{@"phone": phone, @"passcode": code }
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"] && [responseObject objectForKey:@"user"]) {
                                   HCUser* user = [LXServer addToDatabase:@"HCUser" object:[responseObject objectForKey:@"user"] primaryKeyName:@"userID" withMapping:[HCUser resourceKeysForPropertyKeys]];
                                   [user makeLoggedInUser];
                               }
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

+ (void) loginWithToken:(NSString*)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/session_token.json" withMethod:@"POST" withParamaters:@{@"token": token }
                           success:^(id responseObject) {
                               if ([responseObject objectForKey:@"success"] && [[responseObject objectForKey:@"success"] isEqualToString:@"success"] && [responseObject objectForKey:@"user"]) {
                                   HCUser* user = [LXServer addToDatabase:@"HCUser" object:[responseObject objectForKey:@"user"] primaryKeyName:@"userID" withMapping:[HCUser resourceKeysForPropertyKeys]];
                                   [user makeLoggedInUser];
                               }
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
}

- (void) getItems:(NSNumber*)lastUpdated success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
}

- (void) getNewBucketsSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
}

- (void) getBuckets:(NSNumber*)lastUpdated success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
}

-(NSString*) scoreString
{
    return [self.score formattedString];
}

-(NSString*) setupCompletionString
{
    return [self.setupCompletion formattedPercentage];
}

-(BOOL) completedSetup
{
    return [self.setupCompletion integerValue] == 100;
}

# pragma mark setters

- (void) setUserStats:(NSMutableDictionary*)dict
{
    NSLog(@"set user stats");
    if ([dict objectForKey:@"number_buckets"] && [[dict objectForKey:@"number_buckets"] respondsToSelector:@selector(integerValue)]) {
        [self setNumberBuckets:[NSNumber numberWithInt:[[dict objectForKey:@"number_buckets"] intValue]]];
    }
    if ([dict objectForKey:@"number_items"] && [[dict objectForKey:@"number_items"] respondsToSelector:@selector(integerValue)]) {
        [self setNumberItems:[NSNumber numberWithInt:[[dict objectForKey:@"number_items"] intValue]]];
    }
    if ([dict objectForKey:@"score"] && [[dict objectForKey:@"score"] respondsToSelector:@selector(integerValue)]) {
        [self setScore:[NSNumber numberWithInt:[[dict objectForKey:@"score"] intValue]]];
    }
    if ([dict objectForKey:@"setup_completion"] && [[dict objectForKey:@"setup_completion"] respondsToSelector:@selector(integerValue)]) {
        [self setSetupCompletion:[NSNumber numberWithInt:[[dict objectForKey:@"setup_completion"] intValue]]];
    }
    if ([dict objectForKey:@"email"] && NULL_TO_NIL([dict objectForKey:@"email"])) {
        [self setEmail:[dict objectForKey:@"email"]];
    } else {
        [self setEmail:nil];
    }
    if ([dict objectForKey:@"salt"] && NULL_TO_NIL([dict objectForKey:@"salt"])) {
        [self setSalt:[dict objectForKey:@"salt"]];
    }
    if (dict) {
        [[self managedObjectContext] save:nil];
    }
}

- (void) updateTimeZone
{
    NSLog(@"timeZone: %@", [[NSTimeZone localTimeZone] name]);
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/users/%@.json", [self userID]] withMethod:@"PUT" withParamaters:@{@"user":@{@"time_zone":[[NSTimeZone localTimeZone] name]}}
                           success:^(id responseObject) {
                           }
                           failure:^(NSError* error) {
                           }
     ];
}

@end
