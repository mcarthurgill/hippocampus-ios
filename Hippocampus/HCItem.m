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

- (void) destroyAllOfType
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:[self coreObjectName] inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(itemID == %@)", [self itemID]]];
    [request setPredicate:predicate];
    
    NSError* error;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    for (int i=0; i<array.count; ++i) {
        [[[array objectAtIndex:i] managedObjectContext] deleteObject:[array objectAtIndex:i]];
    }
    if (![moc save:&error]) {
        NSLog(@"SAVECHANGES Whoops, couldn't save: %@", [error localizedDescription]);
    } else {
    }
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

+ (NSArray*) search:(NSString*)text
{
    NSArray* words = [text componentsSeparatedByString:@" "];
    
    NSMutableArray* predicates = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < words.count; ++i) {
        if (![[words objectAtIndex:i] isEqualToString:@" "] && ![[words objectAtIndex:i] isEqualToString:@""]) {
            NSLog(@"Word %i: %@", i, [words objectAtIndex:i]);
            [predicates addObject:[NSPredicate predicateWithFormat:@"(message CONTAINS[c] %@)", [words objectAtIndex:i]]];
        }
    }
    
    if (predicates.count > 0) {
        //[NSCompoundPredicate orPredicateWithSubpredicates:predicates]
        return [self items:@"all" withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates] ascending:NO ascendingCriterion:@"updatedAt" index:0 limit:0];
    }
    
    return @[];
}


+ (NSArray*) items:(NSString*)status ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number
{
    return [self items:status ascending:ascending ascendingCriterion:@"createdAt" index:index limit:number];
}

+ (NSArray*) items:(NSString*)status ascending:(BOOL)ascending ascendingCriterion:(NSString*)ascendingCriterion index:(NSUInteger)index limit:(NSUInteger)number
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
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:ascendingCriterion ascending:ascending];
    [request setSortDescriptors:@[descriptor]];
    
    if (number > 0) {
        [request setFetchLimit:number];
    }
    [request setFetchOffset:index];
    
    NSError* error;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (array.count==0) {
        //NO OBJECT FOUND
        return nil;
    } else {
        return (NSArray*) array;
    }
    return nil;
}


+ (NSArray*) items:(NSString*)status withPredicate:(NSPredicate*)pred ascending:(BOOL)ascending ascendingCriterion:(NSString*)ascendingCriterion index:(NSUInteger)index limit:(NSUInteger)number
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"HCItem" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
    
    NSPredicate* predicate;
    if (![status isEqualToString:@"all"]) {
        predicate = [NSPredicate predicateWithFormat:
                                  @"(status == %@) AND (status <> %@)", status, @"deleted"];
    } else {
        predicate = [NSPredicate predicateWithFormat:
                                  @"(status <> %@)", @"deleted"];
    }
    if (pred) {
        [request setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, pred]]];
    } else {
        [request setPredicate:predicate];
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:ascendingCriterion ascending:ascending];
    [request setSortDescriptors:@[descriptor]];
    
    if (number > 0) {
        [request setFetchLimit:number];
    }
    [request setFetchOffset:index];
    
    NSError* error;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (array.count==0) {
        //NO OBJECT FOUND
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
                     [self destroyAllOfType];
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

- (void) assignAndSaveToBucket:(HCBucket*)bucket
{
    if (bucket) {
        [self setBucketID:bucket.bucketID];
        [self setStatus:@"assigned"];
        [self saveWithSuccess:nil failure:nil];
    }
}

- (HCBucket*) bucket
{
    if (self.bucketID && self.bucketID.length > 0) {
        return [LXServer getObjectFromModel:@"HCBucket" primaryKeyName:@"bucketID" primaryKey:self.bucketID];
    }
    return nil;
}

- (NSDate*) reminder
{
    if (self.reminderDate && self.reminderDate.length > 0) {
        return [NSDate timeWithString:self.reminderDate];
    }
    return nil;
}

@end
