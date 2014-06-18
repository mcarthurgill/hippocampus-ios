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

+ (HCUser*) loggedInUser
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
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
    [[LXServer shared] POST:@"/users.json" parameters:@{ @"user" : @{@"phone": phone, @"country_code" : @"1"}} success: ^(NSURLSessionDataTask *task, id responseObject) {
        HCUser* user = [LXServer addToDatabase:@"HCUser" object:nil primaryKeyName:@"userID" withMapping:[HCUser resourceKeysForPropertyKeys]];
        [user setValue:[NSNumber numberWithBool:YES] forKey:@"loggedInUser"];
        [[LXSession thisSession] setUser:user];
        if (successCallback) {
            successCallback(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError* error) {
        if (failureCallback) {
            failureCallback(error);
        }
    }];
}

@end
