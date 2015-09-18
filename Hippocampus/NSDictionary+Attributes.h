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


//NEW

- (NSString*) mediaURL;
- (NSString*) mediaThumbnailURLWithScreenWidth;
- (NSString*) mediaThumbnailURLWithWidth:(NSInteger)width;
- (CGFloat) width;
- (CGFloat) height;
- (CGFloat) mediaSizeRatio;
- (CGFloat) widthForHeight:(CGFloat)height;
- (CGFloat) heightForWidth:(CGFloat)width;
- (CGSize) sizeWithNewWidth:(CGFloat)width;

- (NSString*) avatarURLStringFromPhone;

//OLD

- (NSString*) ID;

- (NSString*) itemID;

- (NSString*) bucketID;

- (NSString*) userID;

- (NSString*) groupID;

- (NSString*) groupName;

- (NSString*) getGroupName;

- (BOOL) belongsToCurrentUser;

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

- (NSString*) audioURL;

- (NSString*) inputMethod;

- (NSString*) description;

- (NSString*) firstName;

- (NSString*) itemsCount;

- (NSString*) bucketType;

- (NSString*) visibility;

- (NSString*) unseenItems;

- (NSString*) itemUserName;

- (NSArray*) bucketUserPairs;

- (NSArray*) links;

- (NSArray*) phones;
- (NSArray*) emails;
- (NSString*) lastName;
- (NSNumber*) recordID;
- (NSString*) note;
- (NSString*) birthday;
- (NSString*) company;
- (NSString*) firstPhone;

- (CLLocation*) location;

- (NSString*) latitude;
- (NSString*) longitude;
- (NSString*) latLongKey;

- (BOOL) hasID;

- (BOOL) isAllNotesBucket;

- (BOOL) hasItems;

- (BOOL) hasBucketsString;

- (BOOL) hasLocation;

- (BOOL) isOutstanding;

- (BOOL) hasMessage;

- (BOOL) hasReminder;

- (BOOL) hasNextReminderDate;

- (BOOL) hasAudioURL;

- (BOOL) hasItemType;

- (BOOL) hasBuckets;

- (BOOL) hasLinks;
- (BOOL) messageIsOnlyLinks;

- (BOOL) equalsObjectBasedOnTimestamp:(NSDictionary*)other;

- (NSString*) firstWord;

- (BOOL) messageIsOneWord;
- (BOOL) notBlank;
- (BOOL) lettersOnly;

- (BOOL) onceReminder;
- (BOOL) yearlyReminder;
- (BOOL) monthlyReminder;
- (BOOL) weeklyReminder;
- (BOOL) dailyReminder;

- (BOOL) hasContacts;
- (BOOL) hasCollaborators;
- (BOOL) isCollaborativeThread;
- (BOOL) hasUnseenItems;

- (BOOL) hasCollaborativeThread;

- (BOOL) hasItemUserName;


- (NSDictionary*) creator;
- (NSArray*) contactCards;
- (NSDictionary*) contactCard;

- (NSMutableDictionary*) cleanDictionary;

- (NSMutableDictionary*) bucketNames;
- (NSMutableArray*) groups;

- (int)indexOfMatchingVideoUrl:(NSString*)imageURL;

// actions

@end
