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
@dynamic name;
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

- (void) destroyAllOfType
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:[self coreObjectName] inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(bucketID == %@)", [self bucketID]]];
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

+ (NSArray*) mostRecent:(NSUInteger)count
{
    NSArray* items = [HCItem items:@"assigned" ascending:NO ascendingCriterion:@"updatedAt" index:0 limit:(count)];
    NSMutableArray* itemIDS = [[NSMutableArray alloc] init];
    for (int i = 0; i < items.count; ++i) {
        [itemIDS addObject:[[items objectAtIndex:i] bucketID]];
    }
    HCBucket* mostRecent = [self mostRecentlyCreatedBucket];
    if (mostRecent && mostRecent.bucketID) {
        [itemIDS addObject:mostRecent.bucketID];
    }
    if (itemIDS.count > 0) {
        return [self bucketsWithPredicate:[NSPredicate predicateWithFormat:@"bucketID IN %@", itemIDS] ascending:YES index:0 limit:(count+2)];
    }
    return nil;
}

+ (NSArray*) search:(NSString*)text
{
    NSArray* words = [text componentsSeparatedByString:@" "];
    
    NSMutableArray* predicates = [[NSMutableArray alloc] init];
    
    NSLog(@"========");
    for (int i = 0; i < words.count; ++i) {
        if (![[words objectAtIndex:i] isEqualToString:@" "] && ![[words objectAtIndex:i] isEqualToString:@""]) {
            NSLog(@"Word %i: %@", i, [words objectAtIndex:i]);
            [predicates addObject:[NSPredicate predicateWithFormat:@"(firstName CONTAINS[c] %@) OR (lastName CONTAINS[c] %@)", [words objectAtIndex:i], [words objectAtIndex:i]]];
        }
    }
    
    if (predicates.count > 0) {
        return [self bucketsWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates] ascending:YES index:0 limit:0];
    }
    
    return @[];
}

+ (NSMutableArray*) alphabetizedArray
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    NSArray* alphabet = [NSArray alphabetLowercase];
    NSMutableArray* predicates = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < alphabet.count; ++i) {
        NSString* l = [alphabet objectAtIndex:i];
        NSArray* results = [self buckets:@"all" firstLetter:l contains:nil ascending:YES index:0 limit:0];
        if (results.count > 0) {
            [array addObject:results];
        } else {
            [array addObject:[[NSArray alloc] init]];
        }
        [predicates addObject:[NSPredicate predicateWithFormat:@"NOT(firstName BEGINSWITH[cd] %@) AND NOT(lastName BEGINSWITH[cd] %@) AND NOT(firstName BEGINSWITH[cd] %@) AND NOT(lastName BEGINSWITH[cd] %@)", [l uppercaseString], [l lowercaseString], [l uppercaseString], [l lowercaseString]]];
    }
    
    NSArray* others = [self bucketsWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates] ascending:YES index:0 limit:0];
    if (others.count > 0) {
        [array addObject:others];
    }
    
    return array;
}

+ (NSArray*) buckets:(NSString *)type ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number
{
    return [self buckets:type firstLetter:nil contains:nil ascending:ascending index:index limit:number];
}

+ (NSArray*) buckets:(NSString *)type firstLetter:(NSString*)firstLetter contains:(NSString*)contains ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number
{
    NSMutableArray* predicates = [[NSMutableArray alloc] init];
    if (![type isEqualToString:@"all"]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(bucketType == %@)", type];
        [predicates addObject:predicate];
    }
    if (firstLetter && firstLetter.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(firstName BEGINSWITH[cd] %@) OR (lastName BEGINSWITH[cd] %@) OR (firstName BEGINSWITH[cd] %@) OR (lastName BEGINSWITH[cd] %@)", [firstLetter uppercaseString], [firstLetter uppercaseString], [firstLetter lowercaseString], [firstLetter lowercaseString]];
        [predicates addObject:predicate];
    }
    if (contains && contains.length > 0) {
        
    }
    NSPredicate* predicate = nil;
    if (predicates.count > 0) {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:(NSArray*)predicates];
    }
    
    return [self bucketsWithPredicate:predicate ascending:ascending index:index limit:number];
}


+ (NSArray*) bucketsWithPredicate:(NSPredicate *)predicate ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"HCBucket" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
    
    if (predicate) {
        [request setPredicate:predicate];
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:ascending];
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

+ (HCBucket*) mostRecentlyCreatedBucket
{
    NSManagedObjectContext *moc = [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"HCBucket" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [request setSortDescriptors:@[descriptor]];
    
    [request setFetchLimit:1];
    
    NSError* error;
    NSMutableArray *array = [NSMutableArray arrayWithArray:[moc executeFetchRequest:request error:&error]];
    if (array.count==0) {
        //NO OBJECT FOUND
        return nil;
    } else {
        return [array firstObject];
    }
    return nil;
}


- (NSString*) titleString
{
    return (self.firstName && self.firstName.length > 0 && self.lastName && self.lastName.length > 0) ? [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName] : (self.firstName && self.firstName.length > 0 ? self.firstName : (self.lastName && self.lastName.length > 0 ? self.lastName : @"Untitled"));
}

- (NSAttributedString*) titleAttributedString
{
    NSString* titleString = [self titleString];
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:titleString];
    NSRange range;
    if (self.firstName && self.firstName.length > 0 && self.lastName && self.lastName.length > 0) {
        range = [titleString rangeOfString:[NSString stringWithFormat:@" %@", self.lastName]];
    } else {
        range = [titleString rangeOfString:titleString];
    }
    [string addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0f] range:range];
    
    return string;
}

- (void) saveWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self setValue:[self titleString] forKey:@"name"];
    
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
//                     if ((!self.bucketID || self.bucketID.length == 0) && [responseObject objectForKey:@"id"]) {
//                         [self destroy];
//                     }
                     [self destroyAllOfType];
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

- (NSString*) descriptionText
{
    if (self.bucketDescription && self.bucketDescription.length > 0) {
        return [self bucketDescription];
    }
    HCItem* first = [self firstItem];
    if (first && first.message && first.message.length > 0) {
        return first.message;
    }
    return nil;
}

- (HCItem*) firstItem
{
    return [[HCItem items:@"all" withPredicate:[NSPredicate predicateWithFormat:@"bucketID == %@", self.bucketID] ascending:NO ascendingCriterion:@"createdAt" index:0 limit:1] firstObject];
}

- (NSArray*) allItems:(NSUInteger)index limit:(NSUInteger)limit
{
    return [HCItem items:@"all" withPredicate:[NSPredicate predicateWithFormat:@"bucketID == %@", self.bucketID] ascending:NO ascendingCriterion:@"createdAt" index:index limit:limit];
}

@end
