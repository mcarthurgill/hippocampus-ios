//
//  LXSession.h
//  CityApp
//
//  Created by Will Schreiber on 4/23/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCUser.h"

@interface LXSession : NSObject

+(LXSession*) thisSession;

@property (strong, nonatomic) HCUser* user;

@end
