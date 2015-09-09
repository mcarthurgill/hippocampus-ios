//
//  SHSearch.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/28/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHSearch.h"

static SHSearch* defaultManager = nil;

@implementation SHSearch

@synthesize cachedBuckets;
@synthesize cachedItems;


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
+ (SHSearch*) defaultManager
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
    self.cachedItems = [[NSMutableDictionary alloc] init];
    self.cachedBuckets = [[NSMutableDictionary alloc] init];
}




# pragma mark get cached items

- (NSMutableArray*) getCachedObjects:(NSString*)type withTerm:(NSString*)term
{
    NSString* foundTerm = [self getCachedResultsTermWithType:type withTerm:term];
    if (foundTerm && [type isEqualToString:@"items"]) {
        return [self.cachedItems objectForKey:foundTerm];
    } else if (foundTerm && [type isEqualToString:@"bucketKeys"]) {
        return [self.cachedBuckets objectForKey:foundTerm];
    }
    return nil;
}

- (NSString*) getCachedResultsTermWithType:(NSString*)type withTerm:(NSString*)term
{
    term = term && [term length] > 0 ? [term lowercaseString] : @"";
    if ([type isEqualToString:@"items"]) {
        while ([term length] > 0) {
            if ([self.cachedItems objectForKey:term])
                return term;
            term = [term substringToIndex:(term.length-1)];
        }
        return nil;
    } else if ([type isEqualToString:@"bucketKeys"]) {
        while ([term length] > 0) {
            if ([self.cachedBuckets objectForKey:term])
                return term;
            term = [term substringToIndex:(term.length-1)];
        }
        return nil;
    }
    return nil;
}




# pragma mark search terms

- (void) searchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self remoteSearchWithTerm:term
                       success:^(id responseObject){
                           if (successCallback) {
                               successCallback(responseObject);
                           }
                       }
                       failure:^(NSError* error){
                           if (failureCallback) {
                               failureCallback(error);
                           }
                       }
     ];
    [self localBucketSearchWithTerm:term
                            success:^(id responseObject){
                                //NSLog(@"response: %@", responseObject);
                                if (successCallback) {
                                    successCallback(responseObject);
                                }
                            }
                            failure:^(NSError* error){
                                if (failureCallback) {
                                    failureCallback(error);
                                }
                            }
     ];
}

- (void) remoteSearchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    ASAPIClient *apiClient = [ASAPIClient apiClientWithApplicationID:@"FVGQB7HR19" apiKey:@"ddecc3b35feb56ab0a9d2570ac964a82"];
    ASRemoteIndex *index = [apiClient getIndex:@"Item"];
    ASQuery* query = [ASQuery queryWithFullTextQuery:term];
    query.numericFilters = [NSString stringWithFormat:@"user_ids_array=%@", [[[LXSession thisSession] user] ID]];
    [index search:query
          success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *answer) {
              [self.cachedItems setObject:[[NSMutableArray alloc] initWithArray:[answer objectForKey:@"hits"]] forKey:[[query fullTextQuery] lowercaseString]];
              for (NSDictionary* tempDict in [answer objectForKey:@"hits"]) {
                  [[tempDict mutableCopy] assignLocalVersionIfNeeded];
              }
              if (successCallback) {
                  successCallback(answer);
              }
          } failure:^(ASRemoteIndex* index, ASQuery* query, NSString* errorMessage){
              NSLog(@"Query failure! ERROR: %@", errorMessage);
              if (failureCallback) {
                  failureCallback(nil);
              }
          }
     ];
}

- (void) localBucketSearchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    term = [term lowercaseString];
    
    NSArray* searchWithBucketKeysArray = [self pullFromBucketKeysArray:term];
    NSMutableArray* newBucketKeys = [[NSMutableArray alloc] init];
    for (NSString* localKey in searchWithBucketKeysArray) {
        NSMutableDictionary* bucket = [LXObjectManager objectWithLocalKey:localKey];
        if (bucket && [bucket firstName] && [[[bucket firstName] lowercaseString] rangeOfString:term].location != NSNotFound) {
            [newBucketKeys addObject:[bucket localKey]];
        }
    }
    [self.cachedBuckets setObject:newBucketKeys forKey:term];
    if (successCallback) {
        successCallback(newBucketKeys);
    }
}

- (NSArray*) pullFromBucketKeysArray:(NSString*)key
{
    return [LXObjectManager objectWithLocalKey:@"bucketLocalKeys"];
    while (key && [key length] > 1) {
        key = [key substringToIndex:([key length]-1)];
        if ([self.cachedBuckets objectForKey:key]) {
            return [self.cachedBuckets objectForKey:key];
        }
    }
    return [LXObjectManager objectWithLocalKey:@"bucketLocalKeys"];
}




@end
