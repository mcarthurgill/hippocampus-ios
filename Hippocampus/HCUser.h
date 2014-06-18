//
//  HCUser.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HCUser : NSManagedObject

@property (nonatomic, retain) NSNumber * loggedInUser;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * countryCode;

+ (HCUser*) loggedInUser;

+ (void) loginUser:(NSString*)phone success:(void (^)(id responseObject))successCallback failure:(void (^)(NSError* error))failureCallback;

@end
