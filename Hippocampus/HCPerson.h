//
//  HCPerson.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HCPerson : NSManagedObject

@property (nonatomic, retain) NSString * personID;
@property (nonatomic, retain) NSString * first_name;
@property (nonatomic, retain) NSString * last_name;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * userID;

@end
