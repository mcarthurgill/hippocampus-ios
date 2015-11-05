//
//  LXLink.h
//  Hippocampus
//
//  Created by Will Schreiber on 11/4/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LXLink)

- (NSString*) bestImage;
- (NSString*) bestTitle;
- (NSString*) URLString;
- (NSString*) bestDescription;

@end
