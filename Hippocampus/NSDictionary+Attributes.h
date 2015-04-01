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

- (NSString*) name;

- (NSString*) reminderDate;

- (NSString*) nextReminderDate;

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

- (BOOL) hasNextReminderDate;

- (BOOL) hasItemType;

- (BOOL) hasBuckets;

- (BOOL) createdFromContacts;

- (BOOL) equalsObjectBasedOnTimestamp:(NSDictionary*)other;

- (NSString*) firstWord;

- (BOOL) messageIsOneWord;

- (BOOL) onceReminder;
- (BOOL) yearlyReminder;
- (BOOL) monthlyReminder;
- (BOOL) weeklyReminder;
- (BOOL) dailyReminder;

- (NSMutableDictionary*) cleanDictionary;

- (NSMutableDictionary*) bucketNames;


// actions

- (void) deleteItemWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
