//
//  LXServer.h
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXServer : AFHTTPSessionManager

+ (LXServer *)shared;

//objects
+ (id) getObjectFromModel:(NSString*)modelName primaryKeyName:(NSString*)primaryKeyName primaryKey:(NSString*)primaryKey;
+ (id) addToDatabase:(NSString*)modelName object:(NSDictionary*)object primaryKeyName:(NSString*)primaryKey withMapping:(NSDictionary*)mapping;

//requests
- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;


@end
