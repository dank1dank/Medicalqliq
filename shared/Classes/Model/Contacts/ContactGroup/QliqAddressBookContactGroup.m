//
//  IPhoneAddressBookContactGroup.m
//  qliqConnect
//
//  Created by Paul Bar on 12/2/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "QliqAddressBookContactGroup.h"

#import "ContactDBService.h"
#import "AddressbookMapping.h"
#import "CNContactMapping.h"
#import "UIDevice-Hardware.h"

@interface QliqAddressBookContactGroup ()

@property (nonatomic, strong) AddressbookMapping *addressbookMapping;
@property (nonatomic, strong) CNContactMapping *contactStoreMapping;

@end

@implementation QliqAddressBookContactGroup

static NSCache * contactsCache;

#define kContactsArrayCacheKey @"contactsArray"

- (void)dealloc {
    self.addressbookMapping = nil;
    self.contactStoreMapping = nil;
}

//Modifing first bit of ABRecordID to avoid duplicating with contact_id
+ (NSInteger) contactIdFromRecordId:(ABRecordID) recordId{
    return recordId | 1 << 31;
}

+ (NSInteger) contactIdFromContactIdentifier:(NSString *)identifier{
    identifier = [identifier componentsSeparatedByString:@":"].firstObject;
    identifier = [identifier stringByReplacingOccurrencesOfString:@"-" withString:@""];
    identifier = [identifier stringByReplacingOccurrencesOfString:@" " withString:@""];
   
    NSCharacterSet *characters = [NSCharacterSet letterCharacterSet];
    identifier = [[identifier componentsSeparatedByCharactersInSet:characters] componentsJoinedByString:@""];
    
    if (identifier.length > 8) {
        identifier = [identifier substringFromIndex:identifier.length - 8];
    }
    
    return [identifier integerValue] | 1 << 30;
}

+ (ABRecordID) recordIdFromContactId:(NSInteger) contactId{
    return (ABRecordID)(contactId ^ 1 << 31);
}

+ (BOOL) isAddressbookContactId:(int) contactId{
    return ((contactId & 0x7FFFFFFF) == contactId);
}

//---

- (void) setupAddressbookMapping
{
    if (is_ios_greater_or_equal_9() && [CNContactStore class]) {
        NSDictionary *mappingDictionary = @{
                                            @"firstName"  : [CNContactMappingValue newWithKey:@"givenName"],
                                            @"middleName" : [CNContactMappingValue newWithKey:@"middleName"],
                                            @"lastName"   : [CNContactMappingValue newWithKey:@"familyName"],
                                            @"mobile"     : [CNContactMappingValue newWithKey:@"phoneNumbers" andLabelType:CNLabelPhoneNumberMobile],
                                            @"phone"      : [CNContactMappingValue newWithKey:@"phoneNumbers" andNotLabelType:CNLabelPhoneNumberMobile],
                                            @"email"      : [CNContactMappingValue newWithKey:@"emailAddresses" andLabelType:CNLabelWork/*CNContactEmailAddressesKey*/]};
        self.contactStoreMapping = [[CNContactMapping alloc] initWithMappingDictionary:mappingDictionary];

    } else {
        NSDictionary *mappingDictionary = @{
                                            @"firstName"  : [AddressbookMappingValue newWithPropertyID:kABPersonFirstNameProperty],
                                            @"middleName" : [AddressbookMappingValue newWithPropertyID:kABPersonMiddleNameProperty],
                                            @"lastName"   : [AddressbookMappingValue newWithPropertyID:kABPersonLastNameProperty],
                                            @"mobile"     : [AddressbookMappingValue newWithPropertyID:kABPersonPhoneProperty andLabel:kABPersonPhoneMobileLabel],
                                            @"phone"      : [AddressbookMappingValue newWithPropertyID:kABPersonPhoneProperty andNotLabel:kABPersonPhoneMobileLabel],
                                            @"email"      : [AddressbookMappingValue newWithPropertyID:kABPersonEmailProperty] };
        self.addressbookMapping = [[AddressbookMapping alloc] initWithMappingDictionary:mappingDictionary];
    }
}


- (id) init
{
    self = [super init];
    if(self)
    {
        if (!contactsCache) contactsCache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark ContactGrop

- (NSUInteger)getPendingCount{
    return 0;
}

- (NSString *) name{
    
    NSString *name = @"iPhone Contacts";
    switch ([UIDevice currentDevice].deviceFamily) {
        case UIDeviceFamilyiPhone:
            break;
        case UIDeviceFamilyiPad:
            name = @"iPad Contacts";
            break;
        case UIDeviceFamilyiPod:
            name = @"iPod Contacts";
            break;
        default:
            break;
    }
    return name;
}

/*creates Contact object from ABRecordRef. Used 'addressbookKeys' to pair ABPerson field with Contacts fields*/
- (Contact *) newContactFromRecordRef:(ABRecordRef) recordRef
{    
    NSInteger contactId = [QliqAddressBookContactGroup contactIdFromRecordId:ABRecordGetRecordID(recordRef)];
    
    //Checking if contact already in database - then load from db
    Contact * contact = [[ContactDBService sharedService] getContactById:contactId];
    
    if (!contact){
        contact = [[Contact alloc] init];
        contact.contactType = ContactTypeIPhoneContact;
        contact.contactId = contactId;
    } else {
        contact.contactType = ContactTypeQliqDuplicate;
    }
    
    [self.addressbookMapping mapObject:contact fromABRecordRef:recordRef];
        
    if (!contact.avatar) {
		CFDataRef avatarDataRef =  ABPersonCopyImageData(recordRef);
        if (avatarDataRef) {
            contact.avatar = [UIImage imageWithData:(__bridge NSData *)avatarDataRef];
			CFRelease(avatarDataRef);
        }
	}

    if (contact.contactType != ContactTypeIPhoneContact){
        [[ContactDBService sharedService] saveContact:contact];
    }
    
    return contact;
}

- (Contact *) newContactFromCNContact:(CNContact *)cnContact
{
    NSInteger contactId = [QliqAddressBookContactGroup contactIdFromContactIdentifier:cnContact.identifier];
    
    //Checking if contact already in database - then load from db
    Contact * contact = [[ContactDBService sharedService] getContactById:contactId];
    
    if (!contact){
        contact = [[Contact alloc] init];
        contact.contactType = ContactTypeIPhoneContact;
        contact.contactId = contactId;
    } else {
        contact.contactType = ContactTypeQliqDuplicate;
    }
    
    [self.contactStoreMapping mapObject:contact fromCNContact:cnContact];
    
    if (!contact.avatar) {
        
        if (cnContact.imageDataAvailable) {
            contact.avatar = [UIImage imageWithData:cnContact.imageData];
        }
    }
    
    if (contact.contactType != ContactTypeIPhoneContact){
        [[ContactDBService sharedService] saveContact:contact];
    }
    
    return contact;
}


- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible {
    
    NSArray * allContacts = [self getContacts];
    
    NSMutableArray * visibleContacts = [[NSMutableArray alloc] init];
    
    for (Contact * contact in allContacts){
        if (contact.contactType != ContactTypeQliqDuplicate){
            [visibleContacts addObject:contact];
        }
    }
    
    return visibleContacts;
}

- (NSArray *)getOnlyContacts
{
    return [self getVisibleContacts];
}

- (NSArray *)getVisibleContacts
{
    NSArray * allContacts = [self getContacts];
    
    NSMutableArray * visibleContacts = [[NSMutableArray alloc] init];
    
    for (Contact * contact in allContacts)
    {
        if (contact.contactType != ContactTypeQliqDuplicate)
            [visibleContacts addObject:contact];
    }
    
    return visibleContacts;
}

- (NSArray *)getNewContacts{
    return nil;
}

- (BOOL)locked{
    return NO;
}

- (BOOL) needRecacheFromAddressBookRef:(ABAddressBookRef) addressBook{
    return [[contactsCache objectForKey:kContactsArrayCacheKey] count] != ABAddressBookGetPersonCount(addressBook);
}

- (BOOL) needRecacheFromCNContactStore:(CNContactStore *)contactStore
{
    BOOL needRecache = NO;
    NSError *error = nil;
   __block NSInteger contactStoreCount = 0;
    
    CNContactFetchRequest * request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactGivenNameKey]];
    
    request.predicate = nil;
    BOOL success = [contactStore enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            contactStoreCount++;
    }];

    if (!success) {
        if (error)
            DDLogError(@"%@", [error localizedDescription]);
        needRecache = YES;
    }
    else
    {
        NSInteger cacheCount = [[contactsCache objectForKey:kContactsArrayCacheKey] count];
        needRecache = cacheCount != contactStoreCount;
    }
    
    return needRecache;
}

- (NSMutableArray *)getDeviceContactsWithCNContacts {
    __block NSMutableArray * contactsArray;
    __block BOOL accessGranted = NO;
    __block BOOL needWait = YES;
    __block CNContactStore * contactStore = [[CNContactStore alloc] init];
    
    //Get Access
    
    dispatch_group_t access = dispatch_group_create();
    
    CNEntityType entityType = CNEntityTypeContacts;
    if([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined)
    {
       dispatch_group_enter(access);
     
        [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error)
         {
             if(granted)
             {
                 accessGranted = granted;
             }
             else
             {
                 DDLogSupport(@"CNContactStore requestAccessForEntityType: Not Granted");
                 if (error)
                 {
                     DDLogError(@"%@", [error localizedDescription]);
                 }
                 
             }
             
             needWait = NO;
             dispatch_group_leave(access);
         }];
    }
    else if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusAuthorized)
    {
        needWait = NO;
        accessGranted = YES;
    }
    else
    {
        needWait = NO;
        if ([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusDenied)
            DDLogSupport(@"CNContactStore authorizationStatusForEntityType: CNEntityTypeContacts - CNAuthorizationStatusDenied");
        else if ([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusRestricted)
            DDLogSupport(@"CNContactStore authorizationStatusForEntityType: CNEntityTypeContacts - CNAuthorizationStatusRestricted");
    }
    
    if (!accessGranted && needWait) {
        dispatch_group_wait(access, DISPATCH_TIME_FOREVER);
    }
    
    
    //Get Contacts
    if (accessGranted && contactStore) {
        
        NSError * contactError = nil;
        [contactStore containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[contactStore.defaultContainerIdentifier]] error:&contactError];
        if (contactError) {
            DDLogError(@"%@", [contactError localizedDescription]);
        }
        else
        {
            /*loading contacts from cache*/
            contactsArray = [contactsCache objectForKey:kContactsArrayCacheKey];
            /*reloading contacts from CNContactStore*/
            if (!contactsArray || [self needRecacheFromCNContactStore:contactStore ])
            {
                
                
                NSArray *keysToFetch = @[CNContactIdentifierKey,
                                         CNContactGivenNameKey,
                                         CNContactMiddleNameKey,
                                         CNContactFamilyNameKey,
                                         CNContactPhoneNumbersKey,
                                         CNContactEmailAddressesKey,
                                         CNContactImageDataAvailableKey,
                                         CNContactImageDataKey];
                
                CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
                
                [self setupAddressbookMapping];
                
                contactsArray = [[NSMutableArray alloc] init];
                
                fetchRequest.sortOrder = [[CNContactsUserDefaults sharedDefaults] sortOrder];
                
                NSError *enumerationError = nil;
                BOOL success = [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&enumerationError usingBlock:^(CNContact * _Nonnull deviceContact, BOOL * _Nonnull stop) {
                    Contact * contact = [self newContactFromCNContact:deviceContact];
                    [contactsArray addObject:contact];
                    
                }];
                
                if (!success ) {
                    DDLogError(@"Can't access to peoples in ContactsStore");
                    if (enumerationError) {
                        DDLogError(@"%@", [enumerationError localizedDescription]);
                    }
                } else {
                    
                    [self sortContactsArray:contactsArray];
                    
                    @synchronized(self){
                        [contactsCache setObject:contactsArray forKey:kContactsArrayCacheKey];
                        DDLogSupport(@"Contacts recached");
                    }
                }
            }
            else
            {
                DDLogSupport(@"Contacts used from cache");
            }
        }
    }
    else
    {
        DDLogError(@"Can't access to iOS addressbook");
        
        NSString *deviceName = NSStringFromUIDeviceFamily([UIDevice currentDevice].deviceFamily);
        
        [[[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1023-TextError", nil)
                                           message:[NSString stringWithFormat:NSLocalizedString(@"1166-TextCannotAccess{DeviceName}Contacts", @"Cannot access {DeviceName} Contacts. Check {DeviceName} privacy settings for Contacts"), deviceName, deviceName]
                                          delegate:nil
                                 cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                 otherButtonTitles:nil] showWithDissmissBlock:NULL];
        return [NSMutableArray array];
    }

    return contactsArray;
    
}

- (NSMutableArray *)getDeviceContactsWithABAddressBook {
    
    NSMutableArray * contactsArray;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    __block BOOL accessGranted = NO;
   
    if (&ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            @autoreleasepool {
//                // Write your code here...
//                // Fetch data from SQLite DB
//            }
//        });
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else { // we're on iOS 5 or older
       accessGranted = YES;
    }
    
    
    if (addressBook && accessGranted)
    {
        /*loading contacts from cache*/
        contactsArray = [contactsCache objectForKey:kContactsArrayCacheKey];
        /*reloading contacts from addressbook*/
        if (!contactsArray || [self needRecacheFromAddressBookRef:addressBook])
        {
            
            [self setupAddressbookMapping];
            
            contactsArray = [[NSMutableArray alloc] init];
            
            CFArrayRef arrayOfAllPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
            
            if (arrayOfAllPeople)
            {
                NSUInteger peopleCounter = 0;
                for (peopleCounter = 0; peopleCounter < CFArrayGetCount(arrayOfAllPeople); peopleCounter++){
                    ABRecordRef thisPerson = CFArrayGetValueAtIndex(arrayOfAllPeople, peopleCounter);
                    Contact * contact = [self newContactFromRecordRef:thisPerson];
                    [contactsArray addObject:contact];
                }
                
                CFRelease(arrayOfAllPeople);
            }
            else
            {
                DDLogError(@"Can't access to peoples in AddressBook");
            }
            
            //sort contacts
            [self sortContactsArray:contactsArray];

            /*save contacts from addressbook to cache*/
            @synchronized(self){
                [contactsCache setObject:contactsArray forKey:kContactsArrayCacheKey];
                DDLogSupport(@"Contacts recached");
            }
        }
        else
        {
            DDLogSupport(@"Contacts used from cache");
        }
        CFRelease(addressBook);
    }
    else
    {
        DDLogError(@"Can't access to iOS addressbook");
        
        NSString *deviceName = NSStringFromUIDeviceFamily([UIDevice currentDevice].deviceFamily);
        
        [[[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1023-TextError", nil)
                                           message:[NSString stringWithFormat:NSLocalizedString(@"1166-TextCannotAccess{DeviceName}Contacts", @"Cannot access {DeviceName} Contacts. Check {DeviceName} privacy settings for Contacts"), deviceName, deviceName]
                                          delegate:nil
                                 cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                 otherButtonTitles:nil] showWithDissmissBlock:NULL];
        return [NSMutableArray array];
    }
    
    return contactsArray;
}

- (void)sortContactsArray:(NSMutableArray *)contactsArray {
    
    [contactsArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        Contact *c1 = (Contact *)obj1;
        Contact *c2 = (Contact *)obj2;
        
        if (c1.lastName.length > 0) {
            
            if (c2.lastName.length > 0)
                return [c1.lastName compare:c2.lastName];
            else if (c2.firstName.length > 0)
                return [c1.lastName compare:c2.firstName];
            else
                return NSOrderedDescending;
            
        } else if (c1.firstName.length > 0) {
            
            if (c2.lastName.length > 0)
                return [c1.firstName compare:c2.lastName];
            else if (c2.firstName.length > 0)
                return [c1.firstName compare:c2.firstName];
            else
                return NSOrderedDescending;
            
        } else {
            
            if (c2.lastName.length > 0 || c2.firstName.length > 0)
                return NSOrderedAscending;
            else
                return NSOrderedSame;
        }
        
        return NSOrderedSame;
    }];
}

- (NSArray *)getContacts
{
    NSMutableArray * contactsArray;
    
    if (is_ios_greater_or_equal_9() && [CNContactStore class])
    {
        contactsArray = [self getDeviceContactsWithCNContacts];
    }
    else
    {
        contactsArray = [self getDeviceContactsWithABAddressBook];
    }
    
     return contactsArray;
}

-(void) addContact:(Contact *)contact
{
    
}



@end
