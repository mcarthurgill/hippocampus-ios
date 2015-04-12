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
                
                if (name && name.length > 1) {
                    NSDictionary *contactInfo = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"name", firstName, @"first_name", lastName, @"last_name", emails, @"emails", phones, @"phones", recordID, @"record_id", note, @"note", bday, @"birthday", company, @"company", image, @"image", nil];
                    [self.allContacts addObject:contactInfo];
                    
                    if (![bucketNames objectForKey:name]) {
                        [self.contactsForAssignment addObject:contactInfo];
                    }
                }
            }
        }
        
        [self sortContacts];

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
    return (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonNoteProperty);
}

- (NSString*) getContactBirthday:(NSDictionary *)contact
{
    return (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonBirthdayProperty);
}

- (NSString*) getContactCompany:(NSDictionary *)contact
{
    return (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)contact, kABPersonOrganizationProperty);
}

- (UIImage*) getContactImage:(NSDictionary *)contact
{
    if (ABPersonHasImageData((__bridge ABRecordRef)contact)) {
        NSData* data = (__bridge_transfer NSData*) ABPersonCopyImageData((__bridge ABRecordRef)contact);
        UIImage* imgd = [UIImage imageWithData:data];
        if (imgd) {
            return imgd;
        }
    }
    return nil;
}

- (void) sortContacts
{
    NSString* sortString = @"last_name";
    ABPersonSortOrdering sortOrder = ABPersonGetSortOrdering();
    if (sortOrder == kABPersonSortByFirstName) {
        sortString = @"name";
    }
    
    NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:sortString ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray * descriptors = [NSArray arrayWithObjects:firstDescriptor, nil];
    NSArray * sortedArray = [[self.contactsForAssignment copy] sortedArrayUsingDescriptors:descriptors];
    self.contactsForAssignment = [sortedArray mutableCopy];
    
    NSArray * sortedAllContacts = [[self.allContacts copy] sortedArrayUsingDescriptors:descriptors];
    self.allContacts = [sortedAllContacts mutableCopy];
}

- (BOOL) sortedByFirstName
{
    return ABPersonGetSortOrdering() == kABPersonSortByFirstName;
}


@end
