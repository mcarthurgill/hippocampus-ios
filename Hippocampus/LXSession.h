//
//  LXSession.h
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCUser.h"

@interface LXSession : NSObject

+(LXSession*) thisSession;

@property (strong, nonatomic) HCUser* user;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void) setVariables;

- (NSMutableArray*) unsavedNotes;
- (NSMutableDictionary*) unsavedNotesDictionary;
- (NSMutableArray*) unsavedNotesForBucket:(NSString*)bucketID;

- (void) addUnsavedNote:(NSMutableDictionary*)note toBucket:(NSString*)bucketID;
- (void) removeUnsavedNote:(NSMutableDictionary*)note fromBucket:(NSString*)bucketID;

@end
