//
//  HCItem.h
//  Hippocampus
//
//  Created by Will Schreiber on 6/18/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HCItem : NSManagedObject

@property (nonatomic, retain) NSString * itemID;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * personID;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * itemType;
@property (nonatomic, retain) NSString * reminderDate;

@end
