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



@end
