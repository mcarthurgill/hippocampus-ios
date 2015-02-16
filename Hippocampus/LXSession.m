//
//  LXSession.m
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXSession.h"

static LXSession* thisSession = nil;

@implementation LXSession

@synthesize user;

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;

//constructor
-(id) init
{
    if (thisSession) {
        return thisSession;
    }
    self = [super init];
    return self;
}


//singleton instance
+(LXSession*) thisSession
{
    if (!thisSession) {
        thisSession = [[super allocWithZone:NULL] init];
    }
    return thisSession;
}


//prevent creation of additional instances
+(id)allocWithZone:(NSZone *)zone
{
    return [self thisSession];
}


//set singleton variables
- (void) setVariables
{
    HCUser* u = [HCUser loggedInUser];
    if (u) {
        [self setUser:u];
    }
}


# pragma mark unsaved notes dictionary


- (NSMutableArray*) unsavedNotes
{
    NSMutableArray* temp = [[NSMutableArray alloc] init];
    NSArray* keys = [[self unsavedNotesDictionary] allKeys];
    for (NSString* k in keys) {
        [temp addObjectsFromArray:[[self unsavedNotesDictionary] objectForKey:k]];
    }
    return temp;
}

- (NSMutableDictionary*) unsavedNotesDictionary
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"unsavedNotes"]) {
        [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"unsavedNotes"]];
    }
    return [[NSMutableDictionary alloc] init];
}

- (NSMutableArray*) unsavedNotesForBucket:(NSString*)bucketID
{
    return [[self unsavedNotesDictionary] objectForKey:bucketID];
}

- (void) addUnsavedNote:(NSMutableDictionary*)note toBucket:(NSString*)bucketID
{
    NSMutableDictionary* temp = [self unsavedNotesDictionary];
    NSMutableArray* tempArray = [self unsavedNotesForBucket:bucketID];
    if (!tempArray) {
        tempArray = [[NSMutableArray alloc] init];
    }
    [tempArray addObject:note];
    [temp setObject:tempArray forKey:bucketID];
    [[NSUserDefaults standardUserDefaults] setObject:temp forKey:@"unsavedNotes"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
