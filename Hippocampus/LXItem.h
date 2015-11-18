//
//  LXItem.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LXItem)

+ (NSMutableDictionary*) createItemWithMessage:(NSString*)message;

+ (NSInteger) unassignedThoughtCount;

- (void) destroyItem;

- (BOOL) hasMedia;
- (NSMutableArray*) media;
- (BOOL) hasAudio;

- (BOOL) hasEmailHTML;
- (NSString*) emailHTML;

- (BOOL) shouldShowAvatar;
- (NSString*) avatarURLString;

- (BOOL) hasAuthorName;
- (NSString*) authorName;

- (NSMutableArray*) bucketsArray;
- (NSMutableArray*) bucketsArrayExcludingLocalKey:(NSString*)key;
- (BOOL) hasBucketsArrayExcludingLocalKey:(NSString*)key;

- (void) updateBucketsWithLocalKeys:(NSMutableArray*)newLocalKeys success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

- (CGFloat) estimatedCellHeight;

- (NSString*) reminderDescriptionString;

- (NSMutableArray*) rawImages;

- (BOOL) hasUnsavedMedia;
- (void) saveMediaIfNecessary;
- (void) removeMediumWithLocalKey:(NSString*)mediumLocalKey;

- (void) addEstimatedRowHeight:(CGFloat)height;

@end
