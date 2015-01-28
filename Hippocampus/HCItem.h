//
//  HCItem.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HCItem : NSManagedObject

@property (nonatomic, retain) NSString * itemID;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * bucketID;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * itemType;
@property (nonatomic, retain) NSString * reminderDate;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * updatedAt;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * inputMethod;

- (id) create;

- (void) destroy;

- (void) destroyAllOfType;

+ (NSMutableDictionary *)resourceKeysForPropertyKeys;

+ (NSArray*) allItems;

+ (NSArray*) search:(NSString*)text;

+ (NSArray*) items:(NSString*)status ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number;

+ (NSArray*) items:(NSString*)status ascending:(BOOL)ascending ascendingCriterion:(NSString*)ascendingCriterion index:(NSUInteger)index limit:(NSUInteger)number;

+ (NSArray*) items:(NSString*)status withPredicate:(NSPredicate*)pred ascending:(BOOL)ascending ascendingCriterion:(NSString*)ascendingCriterion index:(NSUInteger)index limit:(NSUInteger)number;

- (void) saveWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (NSString*) serverObjectName;

- (NSString*) coreObjectName;

- (void) assignAndSaveToBucket:(HCBucket*)bucket;

- (HCBucket*) bucket;

- (NSDate*) reminder;

@end