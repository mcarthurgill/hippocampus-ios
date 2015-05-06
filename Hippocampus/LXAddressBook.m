//
//  LXAddressBook.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

@import AddressBook;

#import "LXAddressBook.h"

static LXAddressBook* thisBook = nil;

@implementation LXAddressBook

@synthesize contactsForAssignment;
@synthesize allContacts;
@synthesize alreadyAskedPermission; 

# pragma mark - Initializers
//constructor
-(id) init
{
    if (thisBook) {
        return thisBook;
    }
    self = [super init];
    return self;
}

//singleton instance
+(LXAddressBook*) thisBook
{
    if (!thisBook) {
        thisBook = [[super allocWithZone:NULL] init];
    }
    return thisBook;
}

//prevent creation of additional instances
+(id)allocWithZone:(NSZone *)zone
{
    return [self thisBook];
}


# pragma mark - Permissions
- (BOOL) permissionDetermined
{
    return ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusNotDetermined;
}

- (BOOL) permissionGranted
{
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (void) requestAccess:(void (^) (BOOL success))completion
{
    ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
        if (granted) {
            [self obtainContactList:^(BOOL success) {
                completion(YES);
            }];
        }
    });
}

- (void) obtainContactList:(void (^) (BOOL success))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.contactsForAssignment = [[NSMutableArray alloc] init];
        self.allContacts = [[NSMutableArray alloc] init];
        CFErrorRef *error = NULL;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
        NSArray* orderedContacts = (__bridge_transfer NSArray*) ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSMutableDictionary *bucketNames = [[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"] bucketNames];

        if (orderedContacts.count > 0) {
            for (int i = 0; i < [orderedContacts count]; i++) {
                NSString *name = [self getContactName:[orderedContacts objectAtIndex:i]];
                NSString *lastName = [self getContactLastName:[orderedContacts objectAtIndex:i]];
                NSString *firstName = [self getContactFirstName:[orderedContacts objectAtIndex:i]];
                NSMutableArray *phones = [self getContactPhoneNumbers:[orderedContacts objectAtIndex:i]];
                NSMutableArray *emails = [self getContactEmails:[orderedContacts objectAtIndex:i]];
                NSString *note = [self getContactNote:[orderedContacts objectAtIndex:i]];
                NSString *bday = [self getContactBirthday:[orderedContacts objectAtIndex:i]];
                NSString *company = [self getContactCompany:[orderedContacts objectAtIndex:i]];
                NSNumber *recordID = [self getContactRecordID:[orderedContacts objectAtIndex:i]];
                UIImage *image = [self getContactImage:[orderedContacts objectAtIndex:i]];
                NSMutableArray *socialMedia = [self getContactSocials:[orderedContacts objectAtIndex:i]];
                
                if (name && name.length > 1) {
                    NSDictionary *contactInfo = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", firstName, @"first_name", lastName, @"last_name", emails, @"emails", phones, @"phones", recordID, @"record_id", note, @"note", bday, @"birthday", company, @"company", image, @"image", socialMedia, @"socials", nil];
                    [self.allContacts addObject:contactInfo];
                    
                    if (![bucketNames objectForKey:name]) {
                        [self.contactsForAssignment addObject:contactInfo];
                    }
                }
            }
        }
        
        [self sortContacts];
        NSLog(@"*******sortedContacts*******");
        completion(YES);
    });
}

- (NSString*) getContactName:(NSDictionary *)contact
{
    NSString *firstName = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonLastNameProperty);
    return [NSString stringWithFormat:@"%@ %@", firstName ? firstName : @"", lastName ? lastName : @""];
}

- (NSString*) getContactLastName:(NSDictionary *)contact
{
    NSString *lastName = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonLastNameProperty);
    return [NSString stringWithFormat:@"%@", lastName ? lastName : @""];
}

- (NSString*) getContactFirstName:(NSDictionary *)contact
{
    NSString *firstName = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonFirstNameProperty);
    return [NSString stringWithFormat:@"%@", firstName ? firstName : @""];
}

- (NSNumber*) getContactRecordID:(NSDictionary *)contact
{
    ABRecordID recordID = ABRecordGetRecordID((__bridge ABRecordRef)contact);
    return [NSNumber numberWithInt:(int)recordID];
}

- (NSMutableArray*) getContactPhoneNumbers:(NSDictionary *)contact
{
    ABMultiValueRef phonesPerPerson = ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonPhoneProperty);
    CFIndex phoneNumberCount = ABMultiValueGetCount(phonesPerPerson);
    NSMutableArray *arrayOfPhones = [[NSMutableArray alloc] init];
    for (CFIndex j = 0; j < phoneNumberCount; j++) {
        [arrayOfPhones addObject:(__bridge NSString *)ABMultiValueCopyValueAtIndex(phonesPerPerson, j)];
    }
    return arrayOfPhones;
}

- (NSMutableArray*) getContactEmails:(NSDictionary *)contact
{
    ABMultiValueRef emailsPerPerson = ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonEmailProperty);
    NSMutableArray *arrayOfEmails = [[NSMutableArray alloc] init];
    CFIndex emailsCount = ABMultiValueGetCount(emailsPerPerson);
    for (CFIndex j = 0; j < emailsCount; j++) {
        [arrayOfEmails addObject:(__bridge NSString *)ABMultiValueCopyValueAtIndex(emailsPerPerson, j)];
    }
    return arrayOfEmails;
}

- (NSString*) getContactNote:(NSDictionary *)contact
{
    NSString *note = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonNoteProperty);
    return note && note.length > 0 ? note : @"";
}

- (NSString*) getContactBirthday:(NSDictionary *)contact
{
    NSString *bday = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonBirthdayProperty);
    return bday ? bday : @"";
}

- (NSString*) getContactCompany:(NSDictionary *)contact
{
    NSString *company = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonOrganizationProperty);
    return company && company.length > 0 ? company : @"";
}

- (UIImage*) getContactImage:(NSDictionary *)contact
{
    UIImage *imgd;
    if (ABPersonHasImageData((__bridge ABRecordRef)contact)) {
        NSData* data = (__bridge_transfer NSData*) ABPersonCopyImageData((__bridge ABRecordRef)contact);
        imgd = [UIImage imageWithData:data];
    }
    return imgd;
}


- (NSMutableArray*) getContactSocials:(NSDictionary*)contact
{
    NSMutableArray *socialsArray = [[NSMutableArray alloc] init];
    
    ABMultiValueRef socials = ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonSocialProfileProperty);
    CFIndex socialsCount = ABMultiValueGetCount(socials);
    
    for (int k=0 ; k<socialsCount ; k++) {
        [socialsArray addObject:(__bridge NSDictionary*)ABMultiValueCopyValueAtIndex(socials, k)];
    }
    
    return socialsArray;
}

- (void) sortContacts
{
    NSString *sortString = @"last_name";
    ABPersonSortOrdering sortOrder = ABPersonGetSortOrdering();
    NSArray *sortedArray;
    
    if (sortOrder == kABPersonSortByFirstName) {
        sortString = @"name";
        NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:sortString ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray * descriptors = [NSArray arrayWithObjects:firstDescriptor, nil];
        sortedArray = [[self.contactsForAssignment copy] sortedArrayUsingDescriptors:descriptors];
    } else {
        NSArray *lastNameSortedArray = [[self.contactsForAssignment copy] sortedArrayUsingComparator:^(id o1, id o2) {
            NSDictionary *cl1 = o1;
            NSDictionary *cl2 = o2;
            
            NSComparisonResult result = [[cl1 objectForKey:@"last_name"] compare:[cl2 objectForKey:@"last_name"] options:NSCaseInsensitiveSearch];
            
            if ([[cl1 objectForKey:@"last_name"] length] < 1) {
                result = [[cl1 objectForKey:@"name"] compare:[cl2 objectForKey:@"last_name"] options:NSCaseInsensitiveSearch];
            }
            if ([[cl2 objectForKey:@"last_name"] length] < 1) {
                result = [[cl1 objectForKey:@"last_name"] compare:[cl2 objectForKey:@"name"] options:NSCaseInsensitiveSearch];
            }
            return result;
        }];
        sortedArray = lastNameSortedArray;
    }
    self.contactsForAssignment = [sortedArray mutableCopy];
    
    
    if (sortOrder == kABPersonSortByFirstName) {
        sortString = @"name";
        NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:sortString ascending:YES selector:@selector(caseInsensitiveCompare:)];
        NSArray * descriptors = [NSArray arrayWithObjects:firstDescriptor, nil];
        sortedArray = [[self.allContacts copy] sortedArrayUsingDescriptors:descriptors];
    } else {
        NSArray *lastNameSortedArray = [[self.allContacts copy] sortedArrayUsingComparator:^(id o1, id o2) {
            NSDictionary *cl1 = o1;
            NSDictionary *cl2 = o2;
            
            NSComparisonResult result = [[cl1 objectForKey:@"last_name"] compare:[cl2 objectForKey:@"last_name"] options:NSCaseInsensitiveSearch];
            
            if ([[cl1 objectForKey:@"last_name"] length] < 1) {
                result = [[cl1 objectForKey:@"name"] compare:[cl2 objectForKey:@"last_name"] options:NSCaseInsensitiveSearch];
            }
            if ([[cl2 objectForKey:@"last_name"] length] < 1) {
                result = [[cl1 objectForKey:@"last_name"] compare:[cl2 objectForKey:@"name"] options:NSCaseInsensitiveSearch];
            }
            return result;
        }];
        sortedArray = lastNameSortedArray;
    }
    self.allContacts = [sortedArray mutableCopy];
}

- (BOOL) sortedByFirstName
{
    return ABPersonGetSortOrdering() == kABPersonSortByFirstName;
}


@end
