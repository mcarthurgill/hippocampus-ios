//
//  NSDictionary+Attributes.h
//  Hippocampus
//
//  Created by Will Schreiber on 2/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface NSDictionary (Attributes)

- (NSString*) ID;

- (NSString*) itemID;

- (NSString*) bucketID;

- (NSString*) userID;

- (NSString*) createdAt;

- (NSString*) updatedAt;

- (NSMutableArray*) buckets;

- (NSString*) bucketsString;

- (NSString*) deviceTimestamp;

- (NSMutableArray*) mediaURLs;

- (NSMutableArray*) croppedMediaURLs;

- (NSString*) message;

- (NSString*) truncatedMessage;

- (NSString*) itemType;

- (NSString*) reminderDate;

- (NSString*) status;

- (NSString*) inputMethod;

- (NSString*) description;

- (NSString*) firstName;

- (NSString*) itemsCount;

- (NSString*) bucketType;

- (CLLocation*) location;

- (BOOL) hasID;

- (BOOL) isAllNotesBucket;

- (BOOL) hasItems;

- (BOOL) hasBucketsString;

- (BOOL) hasLocation;

- (BOOL) isOutstanding;

- (BOOL) hasMediaURLs;

- (BOOL) hasMessage;

- (BOOL) hasReminder;

- (BOOL) hasItemType;

- (BOOL) hasBuckets;

- (BOOL) equalsObjectBasedOnTimestamp:(NSDictionary*)other;

- (NSMutableDictionary*) cleanDictionary;


// actions

- (void) deleteItemWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
