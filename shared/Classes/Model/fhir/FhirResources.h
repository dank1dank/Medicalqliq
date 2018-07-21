//
//  FhirEncounter.h
//  qliq
//
//  Created by Adam Sowa on 10/05/16.
//
//

#import <Foundation/Foundation.h>

//
// WARNING:
// all attributes of FHIR objects are read-only, changes will not propagate to C++ layer
// If attribute/object is mutable then it has explicity set or initWith methods in the interface below

@interface FhirPatient : NSObject
// Attribute access
- (NSString *) uuid;
- (NSString *) hl7id;
- (NSString *) firstName;
- (NSString *) middleName;
- (NSString *) lastName;
- (NSString *) dateOfBirth;
- (NSString *) dateOfDeath;
- (BOOL) deceased;
- (NSString *) race;
- (NSString *) phoneHome;
- (NSString *) phoneWork;
- (NSString *) email;
- (NSString *) insurance;
- (NSString *) address;
- (NSString *) medicalRecordNumber;
- (NSString *) masterPatientindex;
- (NSString *) patientAccountNumber;
- (NSString *) socialSecurityNumber;
- (NSString *) driversLicenseNumber;
- (NSString *) nationality;
- (NSString *) language;
- (NSString *) maritalStatus;
- (NSString *) gender;
- (NSData *) photoData;

// Methods
- (NSString *) displayName;
- (NSString *) fullName;
- (NSString *) demographicsText;
- (int) age;
@end

@interface FhirPractitioner : NSObject
- (NSString *) uuid;
- (void) setUuid:(NSString *)value;
- (NSString *) qliqId;
- (void) setQliqId:(NSString *)value;
- (NSString *) firstName;
- (void) setFirstName:(NSString *)value;
- (NSString *) middleName;
- (void) setMiddleName:(NSString *)value;
- (NSString *) lastName;
- (void) setLastName:(NSString *)value;
@end

@interface FhirParticipant : NSObject
- (id) initWithPractitioner:(FhirPractitioner *)p andTypeText:(NSString *)text;
// Warning: all attributes are read-only, changes will not propagate to C++ layer
- (FhirPractitioner *) practitioner;
- (NSString *) typeText;
@end

@interface FhirLocation : NSObject
- (NSString *) pointOfCare;
- (NSString *) room;
- (NSString *) bed;
- (NSString *) facility;
- (NSString *) building;
- (NSString *) floor;
@end

@interface FhirEncounter : NSObject
- (unsigned int) encounterId;
- (NSString *) uuid;
- (NSString *) visitNumber;
- (FhirPatient *) patient;
- (NSString *) periodStart;
- (NSString *) periodEnd;
- (int) status;
- (FhirLocation *) location;
- (NSString *) summaryTextForRecentsList;
- (NSString *) rawJsonWithReplacedParticipants:(NSSet<FhirParticipant *> *)newParticipants;
@end

@interface FhirEncounterDao : NSObject
+ (BOOL) existsWithUuid:(NSString *)uuid;
+ (FhirEncounter *) findOneWithUuid:(NSString *)uuid;
@end

// Wrapper around std::vector<fhir::Patient>
@interface FhirPatientArray : NSObject
- (NSUInteger) count;
- (FhirPatient *) objectAtIndex:(NSUInteger)index;
@end
