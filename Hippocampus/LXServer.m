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
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
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
    
    if (!NULL_TO_NIL([object valueForKey:@"id"])) {
        return nil;
    }
    
    NSString* object_id = [NSString stringWithFormat:@"%@",[object valueForKey:@"id"]];
    
    id newObject = [LXServer getObjectFromModel:modelName primaryKeyName:primaryKeyName primaryKey:object_id];
    
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
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
    
    [[newObject managedObjectContext] save:nil];
    
    return newObject;
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    if ([method.uppercaseString isEqualToString:@"GET"]) {
        [self GET:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
        }];
    } else if ([method.uppercaseString isEqualToString:@"POST"]) {
        [self POST:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
        }];
    } else if ([method.uppercaseString isEqualToString:@"PUT"]) {
        [self PUT:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
        }];
    } else if ([method.uppercaseString isEqualToString:@"DELETE"]) {
        [self DELETE:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if (failureCallback)
                failureCallback(error);
        }];
    }
}

@end
