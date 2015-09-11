//
//  LXServer.m
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "LXServer.h"
#import "LXAppDelegate.h"
#import "NSString+SHAEncryption.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation LXServer

+ (LXServer*) shared
{
    static LXServer* sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL* baseURL = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"APIRoot"]];
        NSLog(@"%@", [baseURL absoluteString]);
        sharedClient = [[LXServer alloc] initWithBaseURL:baseURL];
        sharedClient.responseSerializer = [AFJSONResponseSerializer serializer];
    });
    return sharedClient;
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self requestPath:path withMethod:method withParamaters:params authType:nil constructingBodyWithBlock:nil success:successCallback failure:failureCallback];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)params constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self requestPath:path withMethod:method withParamaters:params authType:nil constructingBodyWithBlock:block success:successCallback failure:failureCallback];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:params authType:authType success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    [self requestPath:path withMethod:method withParamaters:params authType:authType constructingBodyWithBlock:nil success:successCallback failure:failureCallback];
}

- (void) requestPath:(NSString*)path withMethod:(NSString*)method withParamaters:(NSDictionary*)p authType:(NSString*)authType constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    UIBackgroundTaskIdentifier bgt = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void){
    }];
    
    NSMutableDictionary* params = [[NSMutableDictionary alloc] initWithDictionary:p];
    if ([[LXSession thisSession] user]) {
        [params setObject:@{ @"uid":[[[LXSession thisSession] user] ID], @"token":[NSString userAuthToken] } forKey:@"auth"];
    }
    
    if ([method.uppercaseString isEqualToString:@"GET"]) {
        if ([[LXObjectManager defaultManager] queries] && [[[LXObjectManager defaultManager] queries] count] > 0) {
            [[LXObjectManager defaultManager] runQueries];
        } else {
            [self GET:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
                //NSLog(@"%@", responseObject);
                if (successCallback)
                    successCallback(responseObject);
                [[UIApplication sharedApplication] endBackgroundTask:bgt];
            } failure:^(NSURLSessionDataTask* task, NSError* error) {
                NSLog(@"ERROR! %@", [error localizedDescription]);
                if (failureCallback)
                    failureCallback(error);
                [[UIApplication sharedApplication] endBackgroundTask:bgt];
            }];
        }
    } else if ([method.uppercaseString isEqualToString:@"POST"]) {
        [self POST:path parameters:params constructingBodyWithBlock:block success:^(NSURLSessionDataTask* task, id responseObject) {
            //NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if ([[LXSession thisSession] user]) {
                [[LXObjectManager defaultManager] addQuery:path withMethod:method withLocalKey:[self localStringForParams:p] withObject:p];
            }
            if (failureCallback)
                failureCallback(error);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        }];
    } else if ([method.uppercaseString isEqualToString:@"PUT"]) {
        [self PUT:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            //NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if ([[LXSession thisSession] user]) {
                [[LXObjectManager defaultManager] addQuery:path withMethod:method withLocalKey:[self localStringForParams:p] withObject:p];
            }
            if (failureCallback)
                failureCallback(error);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        }];
    } else if ([method.uppercaseString isEqualToString:@"DELETE"]) {
        [self DELETE:path parameters:params success:^(NSURLSessionDataTask* task, id responseObject) {
            //NSLog(@"%@", responseObject);
            if (successCallback)
                successCallback(responseObject);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        } failure:^(NSURLSessionDataTask* task, NSError* error) {
            NSLog(@"ERROR! %@", [error localizedDescription]);
            if ([[LXSession thisSession] user]) {
                [[LXObjectManager defaultManager] addQuery:path withMethod:method withLocalKey:[self localStringForParams:p] withObject:p];
            }
            if (failureCallback)
                failureCallback(error);
            [[UIApplication sharedApplication] endBackgroundTask:bgt];
        }];
    }
}

- (NSString*) localStringForParams:(NSDictionary*)params
{
    if ([params objectForKey:@"local_key"]) {
        return [params objectForKey:@"local_key"];
    } else if ([params objectForKey:@"item"] && [[params objectForKey:@"item"] objectForKey:@"local_key"]) {
        return [[params objectForKey:@"item"] objectForKey:@"local_key"];
    } else if ([params objectForKey:@"bucket"] && [[params objectForKey:@"bucket"] objectForKey:@"local_key"]) {
        return [[params objectForKey:@"bucket"] objectForKey:@"local_key"];
    }
    return nil;
}

+ (BOOL) errorBecauseOfBadConnection:(NSInteger)code
{
    for (NSNumber* testAgainst in @[@-999,@-1000,@-1001,@-1002,@-1003,@-1004,@-1005,@-1006,@-1007,@-1008,@-1009,@-1018,@-1019,@-1020,@-1100,@-1102]) {
        if ([testAgainst integerValue] == code) {
            return YES;
        }
    }
    return NO;
}




# pragma mark specific callbacks


- (void) updateDeviceToken:(NSData *)token success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback
{
    NSString *tokenString = [[token description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[LXServer shared] requestPath:@"/device_tokens" withMethod:@"POST" withParamaters:@{@"device_token": @{@"ios_device_token": tokenString, @"environment": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ENVIRONMENT"], @"user_id": [[[LXSession thisSession] user] ID]}} success:^(id responseObject) {
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



@end


//int codes[] = {
//    //kCFURLErrorUnknown,     //-998
//    kCFURLErrorCancelled,   //-999
//    kCFURLErrorBadURL,      //-1000
//    kCFURLErrorTimedOut,    //-1001
//    kCFURLErrorUnsupportedURL, //-1002
//    kCFURLErrorCannotFindHost, //-1003
//    kCFURLErrorCannotConnectToHost,     //-1004
//    kCFURLErrorNetworkConnectionLost,   //-1005
//    kCFURLErrorDNSLookupFailed,         //-1006
//    kCFURLErrorHTTPTooManyRedirects,    //-1007
//    kCFURLErrorResourceUnavailable,     //-1008
//    kCFURLErrorNotConnectedToInternet,  //-1009
//    //kCFURLErrorRedirectToNonExistentLocation,   //-1010
//    kCFURLErrorBadServerResponse,               //-1011
//    //kCFURLErrorUserCancelledAuthentication,     //-1012
//    //kCFURLErrorUserAuthenticationRequired,      //-1013
//    //kCFURLErrorZeroByteResource,        //-1014
//    //kCFURLErrorCannotDecodeRawData,     //-1015
//    //kCFURLErrorCannotDecodeContentData, //-1016
//    //kCFURLErrorCannotParseResponse,     //-1017
//    kCFURLErrorInternationalRoamingOff, //-1018
//    kCFURLErrorCallIsActive,                //-1019
//    kCFURLErrorDataNotAllowed,              //-1020
//    //kCFURLErrorRequestBodyStreamExhausted,  //-1021
//    kCFURLErrorFileDoesNotExist,            //-1100
//    //kCFURLErrorFileIsDirectory,             //-1101
//    kCFURLErrorNoPermissionsToReadFile,     //-1102
//    //kCFURLErrorDataLengthExceedsMaximum,     //-1103
//};