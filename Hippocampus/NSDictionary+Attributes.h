//
//  NSDictionary+Attributes.h
//  Hippocampus
//
//  Created by Will Schreiber on 2/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Attributes)

- (NSString*) ID;

- (NSString*) itemID;

- (NSString*) bucketID;

- (NSString*) userID;

- (NSString*) createdAt;

- (NSString*) updatedAt;

- (NSString*) bucketsString;

- (NSString*) deviceTimestamp;

- (NSMutableArray*) mediaURLs;

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

- (BOOL) hasID;

- (BOOL) isAllNotesBucket;

- (BOOL) hasItems;

- (BOOL) hasBucketsString;

- (NSMutableDictionary*) cleanDictionary;

@end
