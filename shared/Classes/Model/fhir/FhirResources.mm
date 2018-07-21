//
//  FhirEncounter.m
//  qliq
//
//  Created by Adam Sowa on 10/05/16.
//
//

#import "FhirResources.h"
#include "qxlib/model/fhir/FhirResources.hpp"
#include "qxlib/dao/fhir/FhirResourceDao.hpp"

namespace {

NSString *toNSString(const std::string& cpp)
{
    if (cpp.empty()) {
        return [NSString new];
    } else {
        return [NSString stringWithUTF8String:cpp.c_str()];
    }
}

std::string toStdString(NSString *nss)
{
    return std::string([nss UTF8String], [nss length]);
}

} // namespace

@interface FhirPatient() {
    fhir::Patient cppPatient;
}

@end

@implementation FhirPatient

- (id) initWithCpp:(const fhir::Patient&) cpp
{
    self = [super init];
    if (self) {
        cppPatient = cpp;
    }
    return self;
}

- (NSString *) uuid
{
    return toNSString(cppPatient.uuid);
}

- (NSString *) hl7id
{
    return toNSString(cppPatient.hl7Id);
}

- (NSString *) firstName
{
    return toNSString(cppPatient.firstName);
}

- (NSString *) middleName
{
    return toNSString(cppPatient.middleName);
}

- (NSString *) lastName
{
    return toNSString(cppPatient.lastName);
}

- (NSString *) dateOfBirth
{
    return toNSString(cppPatient.dateOfBirth);
}

- (NSString *) dateOfDeath
{
    return toNSString(cppPatient.dateOfDeath);
}

- (BOOL) deceased
{
    return cppPatient.deceased;
}

- (NSString *) race
{
    return toNSString(cppPatient.race);
}

- (NSString *) phoneHome
{
    return toNSString(cppPatient.phoneHome);
}

- (NSString *) phoneWork
{
    return toNSString(cppPatient.phoneWork);
}

- (NSString *) email
{
    return toNSString(cppPatient.email);
}

- (NSString *) insurance
{
    return toNSString(cppPatient.insurance);
}

- (NSString *) address
{
    return toNSString(cppPatient.address);
}

- (NSString *) medicalRecordNumber
{
    return toNSString(cppPatient.medicalRecordNumber);
}

- (NSString *) masterPatientindex
{
    return toNSString(cppPatient.masterPatientIndex);
}

- (NSString *) patientAccountNumber
{
    return toNSString(cppPatient.patientAccountNumber);
}

- (NSString *) socialSecurityNumber
{
    return toNSString(cppPatient.socialSecurityNumber);
}

- (NSString *) driversLicenseNumber
{
    return toNSString(cppPatient.driversLicenseNumber);
}

- (NSString *) nationality
{
    return toNSString(cppPatient.nationality);
}

- (NSString *) language
{
    return toNSString(cppPatient.language);
}

- (NSString *) maritalStatus
{
    return toNSString(cppPatient.maritalStatus);
}

- (NSString *) gender
{
    NSString *ret = nil;
    if (cppPatient.gender == fhir::Gender::Male) {
        ret = @"Male";
    } else if (cppPatient.gender == fhir::Gender::Female) {
        ret =  @"Female";
    } else if (cppPatient.gender == fhir::Gender::Other) {
        ret = @"Other";
    }
    return ret;
}

- (NSData *) photoData
{
    NSData *ret = nil;
    const std::string& data = cppPatient.photo.data;
    if (!data.empty()) {        
        ret = [NSData dataWithBytes:data.c_str() length:data.size()];
    }
    return ret;
}

- (NSString *) displayName
{
    return  toNSString(cppPatient.displayName());
}

- (NSString *) fullName
{
    return toNSString(cppPatient.fullName());
}

- (NSString *) demographicsText
{
        return toNSString(cppPatient.demographicsText());
}

- (int) age
{
    return cppPatient.age();
}

@end // FhirPatient

@interface FhirPractitioner() {
    fhir::Practitioner cppPractitioner;
}

- (const fhir::Practitioner&) getCppValue;

@end

@implementation FhirPractitioner

- (id) initWithCpp:(const fhir::Practitioner&) cpp
{
    self = [super init];
    if (self) {
        cppPractitioner = cpp;
    }
    return self;
}

- (const fhir::Practitioner&) getCppValue
{
    return cppPractitioner;
}

- (NSString *) uuid
{
    return toNSString(cppPractitioner.uuid);
}

- (NSString *) qliqId;
{
    return toNSString(cppPractitioner.qliqId);
}

- (NSString *) firstName;
{
    return toNSString(cppPractitioner.firstName);
}

- (NSString *) middleName
{
    return toNSString(cppPractitioner.middleName);
}

- (NSString *) lastName
{
    return toNSString(cppPractitioner.lastName);
}

- (void) setUuid:(NSString *)value
{
    cppPractitioner.uuid = toStdString(value);
}

- (void) setQliqId:(NSString *)value
{
    cppPractitioner.qliqId = toStdString(value);
}

- (void) setFirstName:(NSString *)value
{
    cppPractitioner.firstName = toStdString(value);
}

- (void) setMiddleName:(NSString *)value
{
    cppPractitioner.middleName = toStdString(value);
}

- (void) setLastName:(NSString *)value
{
    cppPractitioner.lastName = toStdString(value);
}

@end // FhirPractitioner

@interface FhirParticipant() {
    fhir::Participant cppParticipant;
}

- (const fhir::Participant&) getCppValue;

@end

@implementation FhirParticipant

- (id) initWithCpp:(const fhir::Participant&) cpp
{
    self = [super init];
    if (self) {
        cppParticipant = cpp;
    }
    return self;
}

- (id) initWithPractitioner:(FhirPractitioner *)p andTypeText:(NSString *)text
{
    self = [super init];
    if (self) {
        cppParticipant.doctor = [p getCppValue];
        cppParticipant.typeText = toStdString(text);
    }
    return self;
}

- (const fhir::Participant&) getCppValue
{
    return cppParticipant;
}

- (FhirPractitioner *) practitioner
{
    return [[FhirPractitioner alloc] initWithCpp:cppParticipant.doctor];
}

- (NSString *) typeText
{
    return toNSString(cppParticipant.typeText);
}

@end // FhirParticipant

@interface FhirLocation() {
    fhir::LocationHl7 cppLocation;
}

@end

@implementation FhirLocation

- (id) initWithCpp:(const fhir::LocationHl7&) cpp
{
    self = [super init];
    if (self) {
        cppLocation = cpp;
    }
    return self;
}

- (NSString *) pointOfCare
{
    return toNSString(cppLocation.pointOfCare);
}

- (NSString *) room
{
    return toNSString(cppLocation.room);
}

- (NSString *) bed
{
    return toNSString(cppLocation.bed);
}

- (NSString *) facility
{
    return toNSString(cppLocation.facility);
}

- (NSString *) building
{
    return toNSString(cppLocation.building);
}

- (NSString *) floor
{
    return toNSString(cppLocation.floor);
}

@end

@interface FhirEncounter() {
    fhir::Encounter encounter;
}

@end

@implementation FhirEncounter

- (id) initWithCpp:(const fhir::Encounter&) cpp
{
    self = [super init];
    if (self) {
        encounter = cpp;
    }
    return self;
}

- (unsigned int) encounterId
{
    return encounter.id;
}

- (NSString *) uuid
{
    return toNSString(encounter.uuid);
}

- (NSString *) visitNumber
{
    return toNSString(encounter.visitNumber);
}

- (FhirPatient *) patient
{
    if (encounter.patient.isEmpty()) {
        return nil;
    } else {
        return [[FhirPatient alloc] initWithCpp:encounter.patient];
    }
}

- (NSString *) periodStart
{
    return toNSString(encounter.periodStart);
}

- (NSString *) periodEnd
{
    return toNSString(encounter.periodEnd);
}

- (int) status
{
    return encounter.status;
}

- (FhirLocation *) location
{
    return [[FhirLocation alloc] initWithCpp:encounter.location];
}

- (NSString *) summaryTextForRecentsList
{
    return toNSString(encounter.summaryTextForRecentsList());
}

- (NSString *) rawJsonWithReplacedParticipants:(NSSet<FhirParticipant *> *)newParticipants
{
    std::set<fhir::Participant> cppParticipants;
    for (FhirParticipant *obj in newParticipants) {
        cppParticipants.insert([obj getCppValue]);
    }
    return toNSString(encounter.rawJsonWithReplacedParticipants(cppParticipants));
}

@end // FhirEncounter

@implementation FhirEncounterDao

+ (BOOL) existsWithUuid:(NSString *)uuid
{
    return fhir::EncounterDao::exists(fhir::EncounterDao::UuidColumn, toStdString(uuid));
}

+ (FhirEncounter *) findOneWithUuid:(NSString *)uuid
{
    fhir::Encounter cpp = fhir::EncounterDao::selectOneBy(fhir::EncounterDao::UuidColumn, toStdString(uuid));
    if (cpp.isEmpty()) {
        return nil;
    } else {
        fhir::EncounterDao::loadChildren(&cpp);
        FhirEncounter *objc = [[FhirEncounter alloc] initWithCpp:cpp];
        return objc;
    }
}

@end // FhirEncounterDao

@interface FhirPatientArray() {
    std::vector<fhir::Patient> cppPatients;
}

@end

@implementation FhirPatientArray

- (id) initWithCpp:(const std::vector<fhir::Patient>&) patients
{
    self = [super init];
    if (self) {
        cppPatients = patients;
    }
    return self;
}

- (NSUInteger) count
{
    return cppPatients.size();
}

- (FhirPatient *) objectAtIndex:(NSUInteger)index
{
    return [[FhirPatient alloc] initWithCpp:cppPatients[index]];
}

@end // FhirPatientArray

FhirPatientArray *FhirPatientArrayNewFromCpp(const std::vector<fhir::Patient>& patients)
{
    return [[FhirPatientArray alloc] initWithCpp:patients];
}
