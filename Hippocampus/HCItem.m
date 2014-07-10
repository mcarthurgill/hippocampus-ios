//
//  HCItem.m
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCItem.h"
#import "LXAppDelegate.h"

@implementation HCItem

@dynamic itemID;
@dynamic message;
@dynamic bucketID;
@dynamic userID;
@dynamic itemType;
@dynamic reminderDate;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic inputMethod;
@dynamic status;


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
                                                             @"itemID": @"id",
                                                             @"message": @"message",
                                                             @"itemType": @"item_type",
                                                             @"reminderDate": @"reminder_date",
                                                             @"inputMethod": @"input_method",
                                                             @"status": @"status",
                                                             @"bucketID": @"bucket_id"
                                                             }];
}


+ (NSArray*) allItems
{
    return [self items:@"all" ascending:NO index:0 limit:500];
}


+ (NSArray*) items:(NSString*)status ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"HCItem" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
    
    if (![status isEqualToString:@"all"]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(status == %@) AND (status <> %@)", status, @"deleted"];
        [request setPredicate:predicate];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(status <> %@)", @"deleted"];
        [request setPredicate:predicate];
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:ascending];
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


- (void) saveWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSString* method = @"PUT";
    NSString* path = [NSString stringWithFormat:@"/%@s/%@.json", [self serverObjectName], self.itemID];
    if (!self.itemID || self.itemID.length == 0) {
        method = @"POST";
        path = [NSString stringWithFormat:@"/%@s.json", [self serverObjectName]];
        [self setInputMethod:@"ios"];
    }
    if (!self.userID || self.userID.length == 0) {
        [self setUserID:[[[LXSession thisSession] user] userID]];
    }
    [LXServer saveObject:self withPath:path method:method mapping:[HCItem resourceKeysForPropertyKeys]
                 success:^(id responseObject) {
                     if ((!self.itemID || self.itemID.length == 0) && [responseObject objectForKey:@"id"]) {
                         [self destroy];
                     }
                     [LXServer addToDatabase:[self coreObjectName] object:responseObject primaryKeyName:@"itemID" withMapping:[HCItem resourceKeysForPropertyKeys]];
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
    return @"item";
}

- (NSString*) coreObjectName
{
    return @"HCItem";
}


@end
