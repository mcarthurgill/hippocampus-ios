//
//  LXAddressBook.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXAddressBook : NSObject

@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableDictionary *contactsDictionary;

+ (LXAddressBook*) thisBook;
- (BOOL) permissionDetermined;
- (BOOL) permissionGranted;
- (void) requestAccess:(void (^) (BOOL success))completion;
- (void) obtainContactList:(void (^) (BOOL success))completion;
- (BOOL) sortedByFirstName;

@end
