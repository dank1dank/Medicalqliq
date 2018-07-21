///
//  ReferringProvider.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//
#import "Contact.h"
#import "ContactGroup.h"
#import "FMResultSet.h"

@interface ReferringProvider : NSObject <Contact> {
	double npi;
	NSString *firstName;
	NSString *lastName;
	NSString *middleName;
	NSString *prefix;
	NSString *suffix;
	NSString *credentials;
    NSString *address;
    NSString *city;
    NSString *state;
    NSString *zip;
    NSString *mobile;
    NSString *phone;
    NSString *fax;
    NSString *email;
	NSString *taxonomyCode;
	NSString *sipUri;
}
@property (nonatomic, readwrite) double npi;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *middleName;
@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) NSString *credentials;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *mobile;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *taxonomyCode;
@property (nonatomic, retain) NSString *sipUri;

- (id) initReferringProviderWithResultSet:(FMResultSet*)resultSet;
@end
