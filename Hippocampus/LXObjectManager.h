//
//  LXObjectManager.h
//  Hippocampus
//
//  Created by Will Schreiber on 8/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXObjectManager : NSObject

+ (LXObjectManager*) defaultManager;
@property (strong, nonatomic) NSMutableDictionary* library;
@property (strong, nonatomic) NSMutableArray* queries;

- (void) runQueries;
- (void) addQuery:(NSString*)path withMethod:(NSString*)method withObject:(NSDictionary*)object withAuthType:(NSString*)authType;


// getting

+ (id) objectWithLocalKey:(NSString*)key;

@end
