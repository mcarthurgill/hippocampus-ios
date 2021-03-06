//
//  LXBucket.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/7/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXBucket.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

static NSString *recentBucketsKey = @"recentBuckeyKeys";
static NSInteger maxRecentCount = 6;

@implementation NSMutableDictionary (LXBucket)

- (void) destroyBucket
{
    if ([self belongsToCurrentUser]) {
        [self destroyRemote:^(id responseObject){
            [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] refreshFromServerWithSuccess:^(id responseObject){
                [[LXObjectManager defaultManager] refreshObjectTypes:@"items" withAboveUpdatedAt:nil success:^(id responseObject){} failure:^(NSError* error){}];
            } failure:^(NSError* error){}];
        } failure:nil];
        NSMutableArray* bucketKeys = [[LXObjectManager objectWithLocalKey:@"bucketLocalKeys"] mutableCopy];
        [bucketKeys removeObject:[self localKey]];
        [NSMutableDictionary removeRecentBucketLocalKey:[self localKey]];
        [LXObjectManager assignLocal:bucketKeys WithLocalKey:@"bucketLocalKeys" alsoToDisk:YES];
    }
}

+ (void) bucketKeysWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:@"/buckets/keys" withMethod:@"GET" withParamaters:nil authType:@"user"
                           success:^(id responseObject){
                               if ([responseObject respondsToSelector:@selector(count)]) {
                                   [LXObjectManager assignLocal:responseObject WithLocalKey:@"bucketLocalKeys" alsoToDisk:YES];
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedBucketLocalKeys" object:nil userInfo:nil];
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           } failure:^(NSError* error){
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) refreshFromServerWithSuccess:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/detail.json", [self ID]] withMethod:@"GET" withParamaters:nil
                           success:^(id responseObject) {
                               
                               dispatch_queue_t backgroundQueue = dispatch_queue_create("com.busproductions.queuecopy24", 0);
                               dispatch_async(backgroundQueue, ^{
                                   BOOL shouldRefresh = NO;
                                   
                                   NSMutableDictionary* bucket = [[responseObject objectForKey:@"bucket"] mutableCopy];
                                   if ([[responseObject objectForKey:@"object_type"] isEqualToString:@"all-thoughts"]) {
                                       [bucket setObject:[NSMutableDictionary allThoughtsLocalKey] forKey:@"local_key"];
                                   }
                                   
                                   NSMutableArray* oldItemKeys = [[NSMutableArray alloc] initWithArray:([[LXObjectManager objectWithLocalKey:[bucket localKey]] itemKeys] ? [[LXObjectManager objectWithLocalKey:[bucket localKey]] itemKeys] : @[])];
                                   
                                   if ([responseObject objectForKey:@"item_keys"] && NULL_TO_NIL([responseObject objectForKey:@"item_keys"])) {
                                       [bucket setObject:[responseObject objectForKey:@"item_keys"] forKey:@"item_keys"];
                                   }
                                   
                                   shouldRefresh = [bucket assignLocalVersionIfNeeded:YES] || shouldRefresh;
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"bucketRefreshed" object:nil userInfo:@{@"bucket":bucket, @"oldItemKeys":oldItemKeys}];
                                   });
                               });
                               
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

+ (NSString*) allThoughtsLocalKey
{
    return [NSString stringWithFormat:@"all-thoughts--%@", [[[LXSession thisSession] user] ID]];
}

+ (NSMutableDictionary*) allBucketNames
{
    NSArray* keys = [LXObjectManager objectWithLocalKey:@"bucketLocalKeys"];
    NSMutableDictionary* names = [[NSMutableDictionary alloc] init];
    for (NSString* key in keys) {
        NSMutableDictionary* bucket = [LXObjectManager objectWithLocalKey:key];
        if (bucket && [bucket firstName]) {
            [names setObject:[bucket firstName] forKey:[bucket firstName]];
        }
    }
    return names;
}

+ (NSMutableArray*) recentBucketLocalKeys
{
    return [LXObjectManager objectWithLocalKey:recentBucketsKey] ? [[LXObjectManager objectWithLocalKey:recentBucketsKey] mutableCopy] : [@[] mutableCopy];
}

+ (void) addRecentBucketLocalKey:(NSString*)key
{
    NSMutableArray* keys = [self recentBucketLocalKeys];
    [keys removeObject:key];
    [keys insertObject:key atIndex:0];
    if ([keys count] > maxRecentCount) {
        [keys removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(maxRecentCount, ([keys count] - maxRecentCount))]];
    }
    [LXObjectManager assignLocal:keys WithLocalKey:recentBucketsKey alsoToDisk:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedBucketLocalKeys" object:nil];
}

+ (void) removeRecentBucketLocalKey:(NSString*)key
{
    NSMutableArray* keys = [self recentBucketLocalKeys];
    [keys removeObject:key];
    [LXObjectManager assignLocal:keys WithLocalKey:recentBucketsKey alsoToDisk:YES];
}

- (NSMutableArray*) items
{
    if ([self objectForKey:@"items"] && NULL_TO_NIL([self objectForKey:@"items"])) {
        return [self objectForKey:@"items"];
    } else {
        return [@[] mutableCopy];
    }
}

- (NSMutableArray*) itemKeys
{
    if ([self objectForKey:@"item_keys"] && NULL_TO_NIL([self objectForKey:@"item_keys"])) {
        return [self objectForKey:@"item_keys"];
    } else {
        return [@[] mutableCopy];
    }
}

- (NSString*) cachedItemMessage
{
    if ([self objectForKey:@"cached_item_message"] && NULL_TO_NIL([self objectForKey:@"cached_item_message"])){
        return [[[self objectForKey:@"cached_item_message"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\uFFFC"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        return [NSString stringWithFormat:@"[Add thoughts to %@]", self.firstName];
    }
    
    return nil;
}

- (NSArray*) authorizedUsers
{
    return [self objectForKey:@"bucket_user_pairs"];
}

- (NSMutableDictionary*) itemAtIndex:(NSInteger)index
{
    return [LXObjectManager objectWithLocalKey:[[self itemKeys] objectAtIndex:index]] ? [LXObjectManager objectWithLocalKey:[[self itemKeys] objectAtIndex:index]] : [@{} mutableCopy];
}

- (NSString*) relationLevel
{
    return [self objectForKey:@"relation_level"] && NULL_TO_NIL([self objectForKey:@"relation_level"]) ? [self objectForKey:@"relation_level"] : @"recent";
}

- (UIColor*) bucketColor
{
    if ([[self relationLevel] isEqualToString:@"recent"]) {
        return [UIColor SHColorBlue];
    } else if ([[self relationLevel] isEqualToString:@"future"]) {
        return [UIColor SHColorGreen];
    } else if ([[self relationLevel] isEqualToString:@"past"]) {
        return [UIColor SHColorOrange];
    }
    return [UIColor SHFontPurple];
}

- (void) addItem:(NSMutableDictionary*)item atIndex:(NSInteger)index
{
    //[[self items] insertObject:item atIndex:index];
    if (![self itemKeys]) {
        [self setObject:[[NSMutableArray alloc] init] forKey:@"item_keys"];
    }
    [self setObject:[NSMutableArray arrayWithArray:[self itemKeys]] forKey:@"item_keys"];
    [[self itemKeys] insertObject:[item localKey] atIndex:index];
    
    [self removeObjectForKey:@"updated_at"];
    [self assignLocalVersionIfNeeded:YES];
    
    [item assignLocalVersionIfNeeded:YES];
}

- (void) removeItemFromBucket:(NSMutableDictionary*)item
{
    NSMutableDictionary* bucket = [LXObjectManager objectWithLocalKey:[self localKey]];
    if ([item localKey] && [bucket itemKeys]) {
        NSMutableArray* itemKeys = [[bucket itemKeys] mutableCopy];
        [itemKeys removeObject:[item localKey]];
        [bucket setObject:itemKeys forKey:@"item_keys"];
        [bucket assignLocalVersionIfNeeded:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"removedItemFromBucket" object:nil userInfo:@{@"item":item,@"bucket":bucket}];
    }
    return;
}

- (void) addCollaboratorsWithContacts:(NSMutableArray*)contacts success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/add_collaborators", [self ID]] withMethod:@"POST" withParamaters:@{@"contacts": contacts} authType:@"none"
                           success:^(id responseObject){
                               if ([responseObject objectForKey:@"bucket"]) {
                                   [LXObjectManager assignObject:[responseObject objectForKey:@"bucket"]];
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           } failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

- (void) removeCollaboratorWithPhone:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/buckets/%@/remove_collaborators", [self ID]] withMethod:@"POST" withParamaters:@{@"phone": phone} authType:@"none"
                           success:^(id responseObject){
                               if ([responseObject objectForKey:@"bucket"]) {
                                   [LXObjectManager assignObject:[responseObject objectForKey:@"bucket"]];
                               }
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }failure:^(NSError *error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
    
}


- (void) changeNameInBucketWithBucketUserPair:(NSMutableDictionary *)bup andNewName:(NSString*)newName success:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback
{
    if (newName && newName.length > 0) {
        [bup setObject:newName forKey:@"name"];
        [bup saveRemoteWithNewAttributes:@{@"name":newName} success:^(id responseObject){
            if ([responseObject objectForKey:@"bucket"]) {
                [LXObjectManager assignObject:[responseObject objectForKey:@"bucket"]];
            }
            if (successCallback) {
                successCallback(successCallback);
            }
        }failure:^(NSError *error){
            if (failureCallback) {
                failureCallback(error);
            }
        }];
    }
}

- (NSMutableArray*) tagsArray
{
    if ([self objectForKey:@"tags_array"] && NULL_TO_NIL([self objectForKey:@"tags_array"])) {
        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for (NSDictionary* tag in [self objectForKey:@"tags_array"]) {
            if ([tag belongsToCurrentUser]) {
                [temp addObject:tag];
            }
        }
        return temp;
    }
    return [[NSMutableArray alloc] init];
}

- (NSMutableArray*) tagsArrayExcludingKey:(NSString*)key
{
    if (!key) {
        return [self tagsArray];
    }
    if ([self objectForKey:@"tags_array"] && NULL_TO_NIL([self objectForKey:@"tags_array"])) {
        NSMutableArray* temp = [[NSMutableArray alloc] init];
        for (NSDictionary* tag in [self objectForKey:@"tags_array"]) {
            if ([tag belongsToCurrentUser] && ![[tag objectForKey:@"local_key"] isEqualToString:key]) {
                [temp addObject:tag];
            }
        }
        return temp;
    }
    return [[NSMutableArray alloc] init];
}

- (BOOL) hasTags
{
    return [[self tagsArray] count] > 0;
}

- (BOOL) hasTagsExcludingKey:(NSString*)key
{
    return [[self tagsArrayExcludingKey:key] count] > 0;
}



- (BOOL) isAllThoughtsBucket
{
    return [self localKey] && [[self localKey] isEqualToString:[NSMutableDictionary allThoughtsLocalKey]];
}

- (BOOL) hasAuthorizedUserID:(NSString *)uID
{
    return ([self objectForKey:@"authorized_user_ids"] && [[self objectForKey:@"authorized_user_ids"] containsObject:[[[LXSession thisSession] user] ID]]) || ([self objectForKey:@"authorized_user_ids"] && [[self objectForKey:@"authorized_user_ids"] containsObject:[NSString stringWithFormat:@"%@",[[[LXSession thisSession] user] ID]]]);
}




# pragma mark tags

- (void) updateTagsWithLocalKeys:(NSMutableArray*)newLocalKeys success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //OLD TAG KEYS
    NSMutableArray* oldTagKeys = [[NSMutableArray alloc] init];
    if ([self tagsArray]) {
        for (NSMutableDictionary* tag in [self tagsArray]) {
            [oldTagKeys addObject:[tag localKey]];
        }
    }
    //CREATE NEW TAGS ARRAY
    NSMutableArray* newTagsArray = [[NSMutableArray alloc] init];
    NSMutableArray* unsavedNewTagsArray = [[NSMutableArray alloc] init];
    for (NSString* key in newLocalKeys) {
        NSMutableDictionary* tempTag = [LXObjectManager objectWithLocalKey:key];
        if (tempTag) {
            [newTagsArray addObject:tempTag];
            if (![tempTag ID]) {
                [unsavedNewTagsArray addObject:tempTag];
            }
        }
        if ([oldTagKeys containsObject:key]) {
            [oldTagKeys removeObject:key];
        }
    }
    
    //SAVE THIS ITEM
    [self setObject:newTagsArray forKey:@"tags_array"];
    [self removeObjectForKey:@"updated_at"];
    [LXObjectManager assignObject:self];
    
    if ([unsavedNewTagsArray count] == 0) {
        //save now
        [self sendUpdateTagsWithLocalKeys:newLocalKeys
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
    } else {
        __block NSInteger currentNumberSaved = 0;
        for (NSMutableDictionary* tag in unsavedNewTagsArray) {
            [tag saveRemote:^(id responseObject){
                ++currentNumberSaved;
                if (currentNumberSaved == [unsavedNewTagsArray count]) {
                    [NSMutableDictionary tagKeysWithSuccess:nil failure:nil];
                    //save now
                    [self sendUpdateTagsWithLocalKeys:newLocalKeys
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
            } failure:^(NSError* error){}];
        }
    }
    
}

- (void) sendUpdateTagsWithLocalKeys:(NSMutableArray*)newLocalKeys success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    //SEND TO SERVER
    [[LXServer shared] requestPath:@"/buckets/update_tags" withMethod:@"PUT" withParamaters:@{@"local_key":[self localKey],@"local_keys":newLocalKeys} authType:@"user"
                           success:^(id responseObject) {
                               //SAVE LOCALLY
                               [LXObjectManager assignObject:responseObject];
                               if (successCallback) {
                                   successCallback(responseObject);
                               }
                           }
                           failure:^(NSError* error) {
                               if (failureCallback) {
                                   failureCallback(error);
                               }
                           }
     ];
}

@end
