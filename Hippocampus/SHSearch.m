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
@synthesize cachedBucketObjects;
@synthesize cachedItems;
@synthesize cachedContacts;
@synthesize cachedTags;


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
    self.cachedBucketObjects = [[NSMutableDictionary alloc] init];
    self.cachedContacts = [[NSMutableDictionary alloc] init];
    self.cachedTags = [[NSMutableDictionary alloc] init];
}




# pragma mark get cached items

- (NSMutableArray*) getCachedObjects:(NSString*)type withTerm:(NSString*)term
{
    if (!term || [term length] == 0) {
        [self setVariables];
    }
    NSString* foundTerm = [self getCachedResultsTermWithType:type withTerm:term];
    if (foundTerm && [type isEqualToString:@"items"]) {
        return [self.cachedItems objectForKey:foundTerm];
    } else if (foundTerm && [type isEqualToString:@"bucketKeys"]) {
        return [self.cachedBuckets objectForKey:foundTerm];
    } else if (foundTerm && [type isEqualToString:@"buckets"]) {
        return [self.cachedBucketObjects objectForKey:foundTerm];
    } else if (foundTerm && [type isEqualToString:@"contacts"]) {
        return [self.cachedContacts objectForKey:foundTerm];
    } else if (foundTerm && [type isEqualToString:@"tagKeys"]) {
        return [self.cachedTags objectForKey:foundTerm];
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
    } else if ([type isEqualToString:@"buckets"]) {
        while ([term length] > 0) {
            if ([self.cachedBucketObjects objectForKey:term])
                return term;
            term = [term substringToIndex:(term.length-1)];
        }
        return nil;
    } else if ([type isEqualToString:@"contacts"]) {
        while ([term length] > 0) {
            if ([self.cachedContacts objectForKey:term])
                return term;
            term = [term substringToIndex:(term.length-1)];
        }
        return nil;
    } else if ([type isEqualToString:@"tagKeys"]) {
        while ([term length] > 0) {
            if ([self.cachedTags objectForKey:term])
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
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.busproductions.searchqueue", 0);
    dispatch_async(backgroundQueue, ^{
        [self remoteSearchWithTerm:term
                           success:^(id responseObject){
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (successCallback) {
                                       successCallback(responseObject);
                                   }
                               });
                           }
                           failure:^(NSError* error){
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (failureCallback) {
                                       failureCallback(error);
                                   }
                               });
                           }
         ];
        [self remoteBucketSearchWithTerm:term hitsPerPage:4
                           success:^(id responseObject){
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (successCallback) {
                                       successCallback(responseObject);
                                   }
                               });
                           }
                           failure:^(NSError* error){
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (failureCallback) {
                                       failureCallback(error);
                                   }
                               });
                           }
         ];
//        [self localBucketSearchWithTerm:term
//                                success:^(id responseObject){
//                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                        if (successCallback) {
//                                            successCallback(responseObject);
//                                        }
//                                    });
//                                }
//                                failure:^(NSError* error){
//                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                        if (failureCallback) {
//                                            failureCallback(error);
//                                        }
//                                    });
//                                }
//         ];
    });
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
                  [[tempDict mutableCopy] assignLocalVersionIfNeeded:NO];
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

- (void) remoteBucketSearchWithTerm:(NSString*)term hitsPerPage:(NSInteger)hits success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    ASAPIClient *apiClient = [ASAPIClient apiClientWithApplicationID:@"FVGQB7HR19" apiKey:@"ddecc3b35feb56ab0a9d2570ac964a82"];
    ASRemoteIndex *index = [apiClient getIndex:@"Bucket"];
    ASQuery* query = [ASQuery queryWithFullTextQuery:term];
    query.numericFilters = [NSString stringWithFormat:@"authorized_user_ids=%@", [[[LXSession thisSession] user] ID]];
    query.hitsPerPage = hits;
    [index search:query
          success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *answer) {
              [self.cachedBucketObjects setObject:[[NSMutableArray alloc] initWithArray:[answer objectForKey:@"hits"]] forKey:[[query fullTextQuery] lowercaseString]];
              NSMutableArray* tempKeys = [[NSMutableArray alloc] init];
              for (NSDictionary* tempDict in [answer objectForKey:@"hits"]) {
                  [[tempDict mutableCopy] assignLocalVersionIfNeeded:NO];
                  if ([tempDict objectForKey:@"local_key"]) {
                      [tempKeys addObject:[tempDict objectForKey:@"local_key"]];
                  }
              }
              [self.cachedBuckets setObject:tempKeys forKey:[[query fullTextQuery] lowercaseString]];
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
    while (key && [key length] > 1) {
        key = [key substringToIndex:([key length]-1)];
        if ([self.cachedBuckets objectForKey:key]) {
            return [self.cachedBuckets objectForKey:key];
        }
    }
    return [LXObjectManager objectWithLocalKey:@"bucketLocalKeys"];
}

- (void) contactsSearchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    term = [term lowercaseString];
    
    NSArray* searchWithContactsArray = [self pullFromContactsArray:term];
    NSMutableArray* newContacts = [[NSMutableArray alloc] init];
    if (term && [term length] > 0) {
        for (NSMutableDictionary* contact in searchWithContactsArray) {
            if (contact && [contact name] && [[[contact name] lowercaseString] rangeOfString:term].location != NSNotFound) {
                [newContacts addObject:contact];
            }
        }
    }
    [self.cachedContacts setObject:newContacts forKey:term];
    if (successCallback) {
        successCallback(newContacts);
    }
}

- (NSArray*) pullFromContactsArray:(NSString*)key
{
    while (key && [key length] > 1) {
        key = [key substringToIndex:([key length]-1)];
        if ([self.cachedContacts objectForKey:key]) {
            return [self.cachedContacts objectForKey:key];
        }
    }
    return [[LXAddressBook thisBook] contactsForAssignment];
}

- (void) localTagSearchWithTerm:(NSString*)term success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    term = [term lowercaseString];
    
    NSArray* searchWithTagKeysArray = [self pullFromTagKeysArray:term];
    NSMutableArray* newTagKeys = [[NSMutableArray alloc] init];
    NSLog(@"array: %@", searchWithTagKeysArray);
    for (NSString* localKey in searchWithTagKeysArray) {
        NSMutableDictionary* tag = [LXObjectManager objectWithLocalKey:localKey];
        if (tag && [tag tagName] && [[[tag tagName] lowercaseString] rangeOfString:term].location != NSNotFound) {
            [newTagKeys addObject:[tag localKey]];
        }
    }
    [self.cachedTags setObject:newTagKeys forKey:term];
    if (successCallback) {
        successCallback(newTagKeys);
    }
}

- (NSArray*) pullFromTagKeysArray:(NSString*)key
{
    while (key && [key length] > 1) {
        key = [key substringToIndex:([key length]-1)];
        if ([self.cachedTags objectForKey:key]) {
            return [self.cachedTags objectForKey:key];
        }
    }
    return [LXObjectManager objectWithLocalKey:@"tagLocalKeys"];
}



@end
