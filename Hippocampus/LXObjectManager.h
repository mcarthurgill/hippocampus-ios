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


// getting

+ (NSMutableDictionary*) objectWithLocalKey:(NSString*)key;

@end
