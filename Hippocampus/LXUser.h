//
//  LXUser.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/6/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (User)

- (void) makeLoggedInUser;
- (void) updateTimeZone;

- (NSString*) email;
- (NSString*) phone;
- (NSString*) salt;
- (NSNumber*) score;
- (NSNumber*) numberItems;
- (NSNumber*) numberBuckets;
- (NSNumber*) setupCompletion;
- (BOOL) completedSetup;

@end
