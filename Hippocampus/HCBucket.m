//
//  HCBucket.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCBucket.h"
#import "LXAppDelegate.h"

@implementation HCBucket

@dynamic createdAt;
@dynamic updatedAt;
@dynamic bucketID;
@dynamic bucketDescription;
@dynamic firstName;
@dynamic lastName;
@dynamic userID;
@dynamic bucketType;

- (id) create
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    return [NSEntityDescription insertNewObjectForEntityForName:[self coreObjectName] inManagedObjectContext:moc];
}

- (void) destroy
{
    [self.managedObjectContext deleteObject:self];
    [self.managedObjectContext save:nil];
}

+ (NSMutableDictionary *)resourceKeysForPropertyKeys
{
    return [[NSMutableDictionary alloc] initWithDictionary:@{
                                                             @"userID": @"user_id",
                                                             @"createdAt": @"created_at",
                                                             @"updatedAt": @"updated_at",
                                                             @"bucketID": @"id",
                                                             @"bucketDescription": @"description",
                                                             @"firstName": @"first_name",
                                                             @"lastName": @"last_name",
                                                             @"bucketType": @"bucket_type"
                                                             }];
}


+ (NSArray*) bucketTypes
{
    return [[NSArray alloc] initWithObjects:@"Person", @"Place", @"Event", @"Other", nil];
}


+ (NSArray*) allBuckets
{
    return [self buckets:@"all" ascending:YES index:0 limit:0];
}

+ (NSArray*) buckets:(NSString *)type ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"HCBucket" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
    
    if (![type isEqualToString:@"all"]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(bucketType == %@)", type];
        [request setPredicate:predicate];
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:ascending];
    [request setSortDescriptors:@[descriptor]];
    
    if (number > 0) {
        [request setFetchLimit:number];
    }
    [request setFetchOffset:index];
    
    NSError* error;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (array.count==0) {
        //NO OBJECT FOUND
        NSLog(@"NO ITEMS FOUND");
        return nil;
    } else {
        return (NSArray*) array;
    }
    return nil;
}


- (NSString*) titleString
{
    return (self.firstName && self.firstName.length > 0 && self.lastName && self.lastName.length > 0) ? [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName] : (self.firstName && self.firstName.length > 0 ? self.firstName : @"Untitled");
}

- (void) saveWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[self managedObjectContext] save:nil];
    
    NSString* method = @"PUT";
    NSString* path = [NSString stringWithFormat:@"/%@s/%@.json", [self serverObjectName], self.bucketID];
    if (!self.bucketID || self.bucketID.length == 0) {
        method = @"POST";
        path = [NSString stringWithFormat:@"/%@s.json", [self serverObjectName]];
    }
    if (!self.userID || self.userID.length == 0) {
        [self setUserID:[[[LXSession thisSession] user] userID]];
    }
    [LXServer saveObject:self withPath:path method:method mapping:[HCBucket resourceKeysForPropertyKeys]
                 success:^(id responseObject) {
                     if ((!self.bucketID || self.bucketID.length == 0) && [responseObject objectForKey:@"id"]) {
                         [self destroy];
                     }
                     [LXServer addToDatabase:[self coreObjectName] object:responseObject primaryKeyName:@"bucketID" withMapping:[HCBucket resourceKeysForPropertyKeys]];
                     if (successCallback)
                         successCallback(responseObject);
                 }
                 failure:^(NSError *error) {
                     if (failureCallback)
                         failureCallback(error);
                 }
     ];
}

- (NSString*) serverObjectName
{
    return @"bucket";
}

- (NSString*) coreObjectName
{
    return @"HCBucket";
}

- (BOOL) isPersonType
{
    return self.bucketType && ([self.bucketType isEqualToString:@"Person"] || [self.bucketType isEqualToString:@"person"]);
}

@end
