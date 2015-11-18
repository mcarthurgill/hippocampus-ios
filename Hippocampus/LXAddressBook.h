//
//  LXAddressBook.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXAddressBook : NSObject

@property (strong, nonatomic) NSMutableArray *contactsForAssignment;
@property (strong, nonatomic) NSMutableArray *allContacts;
@property (nonatomic) BOOL alreadyAskedPermission;

+ (LXAddressBook*) thisBook;

- (BOOL) hasContacts;
- (BOOL) permissionDetermined;
- (BOOL) permissionGranted;

- (void) requestAccess:(void (^) (BOOL success))completion;
- (void) obtainContactList:(void (^) (BOOL success))completion;

- (BOOL) sortedByFirstName;


@end
