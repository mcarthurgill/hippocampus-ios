//
//  NSArray+Attributes.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/10/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Attributes)

- (NSMutableArray*) cleanArray;

- (NSArray*) ignoringObjects:(NSArray*)objects;

- (NSArray*) removeContacts:(NSArray*)objects;

@end
