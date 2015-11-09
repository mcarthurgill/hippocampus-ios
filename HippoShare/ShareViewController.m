//
//  ShareViewController.m
//  HippoShare
//
//  Created by Will Schreiber on 11/5/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "ShareViewController.h"
#include <CommonCrypto/CommonDigest.h>
@import AFNetworking;

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    NSExtensionItem* i = [[[self extensionContext] inputItems] firstObject];
    NSLog(@"NSExtensionItem: %@", i);
    NSItemProvider* iP = [[i attachments] firstObject];
    NSLog(@"NSItemProvider: %@", iP);
    
    if ([iP hasItemConformingToTypeIdentifier:@"public.url"]) {
        [iP loadItemForTypeIdentifier:@"public.url" options:nil
                    completionHandler:^(NSURL* item, NSError* _Null_unspecified error){
                        NSString* urlString;
                        urlString = [item absoluteString];
                        [self sendItemWithMessage:self.textView.text url:urlString media:nil];
                    }
         ];
    } else if ([iP hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
        [iP loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error) {
            if(image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self sendItemWithMessage:self.textView.text url:nil media:@[image]];
                });
            }
        }];
    } else {
        [self sendItemWithMessage:self.textView.text url:nil media:nil];
    }
}

- (void) sendItemWithMessage:(NSString*)message url:(NSString*)url media:(NSArray*)media
{
    NSMutableDictionary* temp = [[NSMutableDictionary alloc] initWithDictionary:@{@"object_type":@"item", @"device_timestamp":[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]}];
    [temp setObject:[self userID] forKey:@"user_id"];
    [temp setObject:[NSString stringWithFormat:@"%@-%@-%@", @"item", [temp objectForKey:@"device_timestamp"], [temp objectForKey:@"user_id"]] forKey:@"local_key"];
    
    if (url && url.length > 0) {
        if (message && [message length] > 0) {
            message = [NSString stringWithFormat:@"%@\n%@", message, url];
        } else {
            message = url;
        }
    }
    
    if (message && message.length > 0) {
        [temp setObject:message forKey:@"message"];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSMutableDictionary *parameters = [@{@"item":temp, @"auth":[self authDictionary]} mutableCopy];
    
    if (media && [media count] > 0) {
        [manager POST:@"https://hippocampus-app.herokuapp.com/items.json" parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
            NSInteger i = 0;
            for (UIImage* image in  media) {
                NSData *data = UIImageJPEGRepresentation(image, 0.99);
                [formData appendPartWithFileData:data name:[NSString stringWithFormat:@"media[]"] fileName:@"tempfile.jpg" mimeType:@"image/jpeg"];
                ++i;
            }
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    } else {
        [manager POST:@"https://hippocampus-app.herokuapp.com/items.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}


# pragma mark auth helpers

- (NSString*) userID
{
    NSMutableDictionary* temp = [[[NSUserDefaults alloc] initWithSuiteName: @"group.busproductions.HippocampusSharingDefaults"] objectForKey:@"user"];
    return temp ? [temp objectForKey:@"id"] : nil;
}

- (NSString*) userSalt
{
    NSMutableDictionary* temp = [[[NSUserDefaults alloc] initWithSuiteName: @"group.busproductions.HippocampusSharingDefaults"] objectForKey:@"user"];
    return temp ? [temp objectForKey:@"salt"] : nil;
}

- (NSDictionary*) authDictionary
{
    if ([self userID]) {
        return @{ @"uid":[self userID], @"token":[self userAuthToken] };
    }
    return nil;
}

- (NSString*)shaEncrypted:(NSString*)string
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    NSData *stringBytes = [string dataUsingEncoding: NSUTF8StringEncoding]; /* or some other encoding */
    if (CC_SHA1([stringBytes bytes], (int)[stringBytes length], digest)) {
        /* SHA-1 hash has been calculated and stored in 'digest'. */
        NSMutableString* sha512 = [[NSMutableString alloc] init];
        for (int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; ++i)
        {
            [sha512 appendFormat: @"%02x", digest[i]];
        }
        return (NSString*)sha512;
    }
    return string;
}

- (NSString*) userAuthToken
{
    if (![self userSalt])
        return nil;
    NSString* salt = [self userSalt];
    if (salt && [salt length] > 0) {
        int userID = [[self userID] intValue];
        double time = [[NSDate date] timeIntervalSince1970] ;
        int time_spec = (int)time / 1000 + userID%116;
        NSString* pre = [salt substringToIndex:8];
        NSString* post = [salt substringFromIndex:8];
        return [self shaEncrypted:[self shaEncrypted:[NSString stringWithFormat:@"%@%i%@", pre, time_spec, post]]];
    }
    return [self shaEncrypted:@""];
}

@end
