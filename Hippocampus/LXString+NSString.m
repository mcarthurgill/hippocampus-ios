//
//  LXString+NSString.m
//  Hippocampus
//
//  Created by Will Schreiber on 1/21/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXString+NSString.h"
#import "NSString+SHAEncryption.h"

@implementation NSString (LXString)

- (NSString*) truncated:(int)length
{
    return length < [self length] ? [NSString stringWithFormat:@"%@ [...]", [self substringWithRange:NSMakeRange(0, length)]] : self;
}

+ (NSString *) randomCongratulations {
    NSArray *arr = [NSArray arrayWithObjects:@"Awesome note.", @"Incredible.", @"You're crushing it.", @"Nice memory!", @"You're getting smarter.", @"Great memory!", @"Details matter.", @"Memory game strong!", @"Killing it.", @"Impressive.", nil];
    return [arr rand];
}

- (NSString*) croppedImageURLToScreenWidth
{
    return [self croppedImageURLToWidth:[[UIScreen mainScreen] bounds].size.width];
}

- (NSString*) croppedImageURLToWidth:(NSInteger) width
{
    if ([self rangeOfString:@"upload/l_playButton/"].location == NSNotFound) {
        return [self stringByReplacingOccurrencesOfString:@"upload/" withString:[NSString stringWithFormat:@"upload/c_scale,w_%@/", [NSNumber numberWithInteger:width*[UIScreen mainScreen].scale]]];
    } else {
        return [self stringByReplacingOccurrencesOfString:@"upload/l_playButton/" withString:[NSString stringWithFormat:@"upload/l_playButton/c_scale,w_%@/", [NSNumber numberWithInteger:width*[UIScreen mainScreen].scale]]];
    }
}

- (NSString*) fileExtension
{
    NSArray* components = [self componentsSeparatedByString:@"."];
    return [components lastObject];
}

- (BOOL) isImageUrl
{
    NSArray *imageEndings = [[NSArray alloc] initWithObjects:@"jpg", @"jpeg", @"png", @"tiff", nil];
    return [imageEndings containsObject:[self fileExtension]];
}

- (NSString*) cloudinaryPublicID
{
    NSArray* components = [self componentsSeparatedByString:@"/"];
    return [[[components lastObject] componentsSeparatedByString:@"."] firstObject];
}

- (CGFloat) heightForTextWithWidth:(CGFloat)width font:(UIFont*)font
{
    if ([self length] == 0)
        return 0.0f;
    CGRect rect = [self boundingRectWithSize:CGSizeMake(width, 100000) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:font} context:nil];
    return rect.size.height;
}

- (NSString*) objectTypeFromLocalKey
{
    if ([self rangeOfString:@"-"].location == NSNotFound)
        return nil;
    
    return [self substringToIndex:[self rangeOfString:@"-"].location];
}

- (NSString*) deviceTimestampFromLocalKey
{
    if ([self rangeOfString:@"-"].location == NSNotFound)
        return nil;
    NSString* secondHalf = [self substringFromIndex:([self rangeOfString:@"-"].location+1)];
    if ([secondHalf rangeOfString:@"-"].location == NSNotFound)
        return nil;
    return [secondHalf substringToIndex:[secondHalf rangeOfString:@"-"].location];
}

- (NSString*) userIDFromLocalKey
{
    if ([self rangeOfString:@"-"].location == NSNotFound)
        return nil;
    NSString* secondHalf = [self substringFromIndex:([self rangeOfString:@"-"].location+1)];
    if ([secondHalf rangeOfString:@"-"].location == NSNotFound)
        return nil;
    return [secondHalf substringFromIndex:([secondHalf rangeOfString:@"-"].location+1)];
}

- (NSString*) linkLocalKeyFromURLString
{
    return [NSString stringWithFormat:@"link--%@", [self shaEncrypted]];
}

- (NSString*) firstWord
{
    return [[self componentsSeparatedByString:@" "] objectAtIndex:0];
}

@end

