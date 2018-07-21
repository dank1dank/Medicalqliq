 //
//  FaxContact.h
//  qliq
//
//  Created by Adam Sowa.
//
//

#import <Foundation/Foundation.h>

@interface FaxContact : NSObject

- (int) databaseId;
- (NSString *) uuid;

- (NSString *) faxNumber;
- (void) setFaxNumber: (NSString *)value;

- (NSString *) voiceNumber;
- (void) setVoiceNumber: (NSString *)value;

- (NSString *) organization;
- (void) setOrganization: (NSString *)value;

- (NSString *) contactName;
- (void) setContactName: (NSString *)value;

- (BOOL) isCreatedByUser;
- (void) setIsCreatedByUser: (BOOL)value;

- (NSString *) groupQliqId;

// Methods
- (NSString *) toMultiLineString;

// Low level conversion methods, for qxlib internals
- (id) initWithCpp2:(void *)cppObject;
- (void *) cppValue;

@end
