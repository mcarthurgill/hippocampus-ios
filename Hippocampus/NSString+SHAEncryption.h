//
//  NSString+SHAEncryption.h
//  TimeTesting
//
//  Created by William L. Schreiber on 1/2/14.
//  Copyright (c) 2014 Bus Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SHAEncryption)

+ (NSString*) random:(NSInteger)len;

- (NSString*) shaEncrypted;

+ (NSString*) userAuthToken;

@end
