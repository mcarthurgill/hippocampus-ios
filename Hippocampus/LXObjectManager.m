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
@synthesize queries;


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
    self.queries = [[NSMutableArray alloc] init];
    [self initializeWithFailedQueries];
}


# pragma mark server interface

- (void) initializeWithFailedQueries
{
    NSLog(@"failed-queries: %@", [[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"]);
    if ([[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"] && [[[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"] count] > 0) {
        [self.queries addObjectsFromArray:[[NSUserDefaults  standardUserDefaults] objectForKey:@"failed-queries"]];
        NSLog(@"failed-queries-array: %@", self.queries);
    }
}

- (void) runQueries
{
    if ([self.queries count] > 0) {
        NSArray* query = [self.queries firstObject];
        [[LXServer shared] requestPath:query[0] withMethod:query[1] withParamaters:query[2] authType:query[3]
                               success:^(id responseObject){
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"successfulQueryDelayed" object:nil userInfo:@{@"query":query}];//,@"responseObject":responseObject
                                   [self removeQuery:query];
                                   [self saveQueries];
                                   [self runQueries];
                               }
                               failure:^(NSError* error){
                                   if (![LXServer errorBecauseOfBadConnection:error.code]) {
                                       [self removeQuery:query];
                                       [self saveQueries];
                                       [self runQueries];
                                   }
                               }
         ];
    }
    [self saveQueries];
}

- (void) addQuery:(NSString*)path withMethod:(NSString*)method withObject:(NSDictionary*)object withAuthType:(NSString*)authType
{
    [self.queries addObject:@[path, method, object, authType]];
    [self runQueries];
}

- (void) removeQuery:(id)query
{
    [self.queries removeObject:query];
}

- (void) saveQueries
{
    if ([self.queries count] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.queries forKey:@"failed-queries"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"failed-queries"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}




# pragma mark getting

+ (id) objectWithLocalKey:(NSString*)key
{
    if (key && key.length > 0) {
        return [[[LXObjectManager defaultManager] library] objectForKey:key] ? [[[[LXObjectManager defaultManager] library] objectForKey:key] mutableCopy] : [[[NSUserDefaults standardUserDefaults] objectForKey:key] mutableCopy];
    }
    return nil;
}


@end
