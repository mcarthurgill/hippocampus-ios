//
//  LXObjectManager.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXObjectManager.h"

static LXObjectManager* defaultManager = nil;

@implementation LXObjectManager

@synthesize library;


# pragma mark singleton resource

//constructor
-(id) init
{
    if (defaultManager) {
        return defaultManager;
    }
    self = [super init];
    return self;
}


//singleton instance
+ (LXObjectManager*) defaultManager
{
    if (!defaultManager) {
        defaultManager = [[super allocWithZone:NULL] init];
        [defaultManager setVariables];
    }
    return defaultManager;
}


//prevent creation of additional instances
+ (id) allocWithZone:(NSZone *)zone
{
    return [self defaultManager];
}


//set singleton variables
- (void) setVariables
{
    self.library = [[NSMutableDictionary alloc] init];
}



# pragma mark getting

+ (NSMutableDictionary*) objectWithLocalKey:(NSString*)key
{
    if (key && key.length > 0) {
        return [[[LXObjectManager defaultManager] library] objectForKey:key] ? [[[[LXObjectManager defaultManager] library] objectForKey:key] mutableCopy] : [[[NSUserDefaults standardUserDefaults] objectForKey:key] mutableCopy];
    }
    return nil;
}


@end
