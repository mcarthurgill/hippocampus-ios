//
//  HCBucket.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface HCBucket : NSManagedObject

@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * updatedAt;
@property (nonatomic, retain) NSString * bucketID;
@property (nonatomic, retain) NSString * bucketDescription;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * bucketType;

- (id) create;

- (void) destroy;

- (void) destroyAllOfType;

+ (NSMutableDictionary *)resourceKeysForPropertyKeys;

+ (NSArray*) bucketTypes;

+ (NSArray*) allBuckets;

+ (NSArray*) mostRecent:(NSUInteger)count;

+ (NSArray*) search:(NSString*)text;

+ (NSMutableArray*) alphabetizedArray;

+ (NSArray*) buckets:(NSString*)type ascending:(BOOL)ascending index:(NSUInteger)index limit:(NSUInteger)number;

- (NSString*) titleString;

- (NSAttributedString*) titleAttributedString;

- (void) saveWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (NSString*) serverObjectName;

- (NSString*) coreObjectName;

- (BOOL) isPersonType;

- (NSString*) descriptionText;

- (NSArray*) allItems:(NSUInteger)index limit:(NSUInteger)limit;

@end
