//
//  NSString+SHAEncryption.m
//  TimeTesting
//
//  Created by William L. Schreiber on 1/2/14.
//  Copyright (c) 2014 Bus Productions. All rights reserved.
//

#import "NSString+SHAEncryption.h"
#include <CommonCrypto/CommonDigest.h>

@implementation NSString (SHAEncryption)

+ (NSString*) random:(NSInteger)len
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }
    return randomString;
}

-(NSString*)shaEncrypted
{
   unsigned char digest[CC_SHA1_DIGEST_LENGTH];
   NSData *stringBytes = [self dataUsingEncoding: NSUTF8StringEncoding]; /* or some other encoding */
   if (CC_SHA1([stringBytes bytes], [stringBytes length], digest)) {
      /* SHA-1 hash has been calculated and stored in 'digest'. */
      NSMutableString* sha512 = [[NSMutableString alloc] init];
      for (int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; ++i)
      {
         [sha512 appendFormat: @"%02x", digest[i]];
      }
      return (NSString*)sha512;
   }
   return self;
}

+ (NSString*) userAuthToken
{
    NSString* salt = [[[LXSession thisSession] user] salt];
    if (salt && [salt length] > 0) {
        int userID = [[[[LXSession thisSession] user] ID] intValue];
        double time = [[NSDate date] timeIntervalSince1970] ;
        int time_spec = (int)time / 1000 + userID%116;
        NSString* pre = [salt substringToIndex:8];
        NSString* post = [salt substringFromIndex:8];
        return [[[NSString stringWithFormat:@"%@%i%@", pre, time_spec, post] shaEncrypted] shaEncrypted];
    }
    return [@"" shaEncrypted];
}

@end
