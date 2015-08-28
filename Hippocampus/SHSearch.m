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
    if ([type isEqualToString:@"items"]) {
        term = term && [term length] > 0 ? [term lowercaseString] : @"";
        while ([term length] > 0) {
            if ([self.cachedItems objectForKey:term])
                return [self.cachedItems objectForKey:term];
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
    
}




@end
