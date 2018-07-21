//
//  CreateTestData.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 7/27/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "CreateTestData.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "QliqUser.h"
#import "PatientVisit.h"
#import "Patient.h"
#import "PatientVisitService.h"
#import "PatientService.h"
#import "CareTeamMember.h"
#import "CareteamService.h"
#import "FacilityService.h"
#import "Facility.h"
#import "Helper.h"
#import "NSDate+Helper.h"
#import "Group.h"
#import "GroupService.h"
#import "Floor.h"

#import "ChatMessage.h"
#import "Conversation.h"
#import "QliqConnectModule.h"
#import "QliqUserService.h"

@implementation CreateTestData

-(Conversation *) createTestConversationWith:(id<Contact>)contact
{
    QliqConnectModule* module = [QliqConnectModule sharedQliqConnectModule];
    return [module createConversationWithUser:contact subject:@"Testing chat"];
    
}

-(void) create:(NSInteger)messageCount messagesWithUser:(id<Contact>)user
{
    Conversation *conversation = [self createTestConversationWith:user];
    QliqUser *me = [UserSessionService currentUserSession].user;
    for(int i = 0; i < messageCount; i++)
    {        
        ChatMessage *newMessage = [[ChatMessage alloc] initWithPrimaryKey:0];
        newMessage.conversationId = conversation.conversationId;
        if(i % 2)
        {
            newMessage.fromQliqId = me.email;
            newMessage.toQliqId = [user email];
        }
        else
        {
            newMessage.fromQliqId = [user email];
            newMessage.toQliqId = me.email;
        }
        newMessage.text = [NSString stringWithFormat:@"Test message text # %d", i];///@"Test message text.";
        newMessage.timestamp = [[NSDate date] timeIntervalSince1970];
        newMessage.readAt = newMessage.timestamp;
        newMessage.lastSentAt = newMessage.timestamp;
        newMessage.ackRequired = !(i % 12);
        newMessage.subject = conversation.subject;
        newMessage.metadata = [Metadata createNew];
        newMessage.metadata.isRevisionDirty = YES;
        newMessage.messageId = [ChatMessage addMessage:newMessage];
        [newMessage release];
    }
}

- (void) createMyRounds
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    QliqUserService *qliqUserService = [[QliqUserService alloc] init];
    QliqUser *toUser = [qliqUserService getUserWithId:@"p3@staff.demo"];
    [self create:1000 messagesWithUser:toUser];
    [qliqUserService release];
    
	NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MM/dd/yyyy"];
    [format setTimeZone:[NSTimeZone localTimeZone]];
    
	GroupService *groupService = [[GroupService alloc] init];
    
	QliqUser *user = [UserSessionService currentUserSession].user;

	FacilityService *facSvc = [[FacilityService alloc] init];
	Facility *fac = [[Facility alloc] init];
    fac.npi = [NSNumber numberWithInt:1];
    fac.name = @"test facility";
    [facSvc saveFacility:fac];
    
    Facility *fac2 = [[Facility alloc] init];
    fac2.npi = [NSNumber numberWithInt:2];
    fac2.name = @"test facility 2";
    [facSvc saveFacility:fac2];
    
    Group *group = [[Group alloc] init];
    group.name = @"test group 1";
    [groupService saveGroup:group];
    [facSvc addGroup:group toFacility:fac];
    
    Group *group2 = [[Group alloc] init];
    group2.name = @"test group 2";
    [groupService saveGroup:group2];
    [facSvc addGroup:group2 toFacility:fac];
    
    Floor *floor1 = [[Floor alloc] init];
    floor1.name = @"floor 1";
    [facSvc addFloor:floor1 toFacility:fac];
	
    Floor *floor2 = [[Floor alloc] init];
    floor2.name = @"floor 2";
    [facSvc addFloor:floor2 toFacility:fac];
    
    Group *group3 = [[Group alloc] init];
    group3.name = @"test group 3";
    [groupService saveGroup:group3];
    [facSvc addGroup:group3 toFacility:fac2];
    
    Group *group4 = [[Group alloc] init];
    group4.name = @"test group 4";
    [groupService saveGroup:group4];
    [facSvc addGroup:group4 toFacility:fac2];
    
    Floor *floor3 = [[Floor alloc] init];
    floor3.name = @"floor 3";
    [facSvc addFloor:floor3 toFacility:fac2];
    
    Floor *floor4 = [[Floor alloc] init];
    floor4.name = @"floor 4";
    [facSvc addFloor:floor4 toFacility:fac2];

    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    NSDate *today = [NSDate dateWithoutTime];
	
	PatientService *patService = [[PatientService alloc] init];
	Patient	*pat = [[Patient alloc] init];
	pat.firstName = @"George";
	pat.lastName = @"Washington";
	pat.middleName = @"K";
	pat.gender = @"Male";
	pat.race = @"White";
 	[components setYear:-40];
	NSDate *date = [gregorianCal dateByAddingComponents:components toDate:today options:0];
	pat.dateOfBirth = date;
	[patService savePatient:pat];
    
    Patient *pat2 = [[Patient alloc] init];
    pat2.firstName = @"Boris";
    pat2.lastName = @"Yelcin";
    pat2.gender = @"Male";
    pat2.race = @"White";
 	[components setYear:-45];
	date = [gregorianCal dateByAddingComponents:components toDate:today options:0];
	pat2.dateOfBirth = date;
    [patService savePatient:pat2];
	
	CareTeamMember *cm = [[CareTeamMember alloc] init];
	CareteamService *cs = [[CareteamService alloc] init]; 
	cm.user = user;
	cm.admit = YES;
	cm.active = YES;
	[cs saveCareteamMember:cm];
    NSArray * careteamIds = [cs getCareteamIdsOfUser:user];
 
	PatientVisit *pv = [[PatientVisit alloc] init];
	PatientVisitService *pvSvc = [[PatientVisitService alloc] init];
	pv.careteamId = [careteamIds objectAtIndex:0];
	pv.patientGuid = pat.guid;
	pv.facilityNpi = fac.npi;
	pv.floorId = floor1.floorId;
	pv.room = @"123";
	pv.mrn = @"36636636";
    pv.type = @"Appointment";
    
    PatientVisit *pv2 = [[PatientVisit alloc] init];
    pv2.careteamId = [careteamIds objectAtIndex:0];
	pv2.patientGuid = pat2.guid;
	pv2.facilityNpi = fac2.npi;
	pv2.floorId = floor3.floorId;
	pv2.room = @"321";
	pv2.mrn = @"36636636";
    pv2.type = @"Round";
    
    
	[components setDay:-3];
	date = [gregorianCal dateByAddingComponents:components toDate:today options:0];
	pv.admitDate = date;
	pv2.admitDate = date;
   
    pv.facilityNpi = fac.npi;
    pv2.facilityNpi = fac2.npi;
    
	[pvSvc savePatientVisit:pv];
    [pvSvc savePatientVisit:pv2];

	[pvSvc release];
	[pv release];
    [pv2 release];
	[cs release];
	[cm release];
	[patService release];
	[pat release];
    [pat2 release];
	[fac release];
    [fac2 release];
	[facSvc release];
    [groupService release];
    [group release];
    [group2 release];
    [group3 release];
    [group4 release];
    [floor1 release];
    [floor2 release];
    [floor3 release];
    [floor4 release];
	/*
	newPatId = [self createPatient:@"George":@"":@"Washington":@"02/22/1932":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"200" :@"12213"];
	
	newPatId = [self createPatient:@"John":@"":@"Adams":@"10/30/1935":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"William Stewart Agras": physicianObj.physicianNpi :@"201" :@"12211"];

	
	newPatId = [self createPatient:@"Martha":@"":@"Dandridge":@"6/2/1931":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Frederick Banting": physicianObj.physicianNpi :@"202" :@"12212"];
	
	newPatId = [self createPatient:@"Lucy":@"Ware":@"Webb":@"8/28/1931":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Charles Best": physicianObj.physicianNpi :@"203" :@"12213"];
	
	newPatId = [self createPatient:@"Lucretia":@"":@"Rudolph":@"4/19/1932":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"204" :@"12214"];
	
	newPatId = [self createPatient:@"Helen":@"Louise":@"Herron":@"6/2/1961":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Norman Bethune": physicianObj.physicianNpi :@"205" :@"12215"];
	newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Theodor Billroth": physicianObj.physicianNpi :@"206" :@"12216"];
	
	newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Guy de Chauliac": physicianObj.physicianNpi :@"207" :@"12217"];

	newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianObj.physicianNpi :@"207" :@"12217"];

	newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"William Osler Abbott": physicianObj.physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"206" :@"12213"];
	
	newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianObj.physicianNpi :@"207" :@"12213"];

	newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Salvador Mazza": physicianObj.physicianNpi :@"2000" :@"12213"];

	newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"209" :@"12213"];

	newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Girolamo Fracastoro": physicianObj.physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Rutherford":@"B.":@"Hayes":@"10/04/1922":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Girolamo Fracastoro": physicianObj.physicianNpi :@"201" :@"12213"];

	newPatId = [self createPatient:@"Ellen":@"Lewis":@"Herndon":@"8/30/1937":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"202" :@"12213"];

	newPatId = [self createPatient:@"Frances":@"Clara":@"Folsom":@"7/21/1964":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"203" :@"12213"];

	newPatId = [self createPatient:@"Ida":@"":@"Saxton":@"6/8/1947":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Leo Kanner": physicianObj.physicianNpi :@"200" :@"12213"];

	newPatId = [self createPatient:@"Edith":@"Kermit":@"Carow":@"8/6/1961":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"204" :@"12213"];

	newPatId = [self createPatient:@"Jacqueline":@"Lee":@"Bouvier":@"7/28/1929":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"205" :@"12213"];

	newPatId = [self createPatient:@"Claudia":@"Alta":@"Taylor":@"12/22/1912":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"110" :@"12213"];

	newPatId = [self createPatient:@"Thelma":@"Catherine":@"Ryan":@"3/16/1912":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"100" :@"12213"];

	newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"100" :@"12213"];

	newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"400" :@"12213"];

	newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"600" :@"12213"];

	newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"700" :@"12213"];
	

	newPatId = [self createPatient:@"George":@"":@"Washington":@"02/22/1932":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"200" :@"12213"];
	
	newPatId = [self createPatient:@"John":@"":@"Adams":@"10/30/1935":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"William Stewart Agras": physicianObj.physicianNpi :@"201" :@"12211"];
	
	
	newPatId = [self createPatient:@"Martha":@"":@"Dandridge":@"6/2/1931":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Frederick Banting": physicianObj.physicianNpi :@"202" :@"12212"];
	
	newPatId = [self createPatient:@"Lucy":@"Ware":@"Webb":@"8/28/1931":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Charles Best": physicianObj.physicianNpi :@"203" :@"12213"];
	
	newPatId = [self createPatient:@"Lucretia":@"":@"Rudolph":@"4/19/1932":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"204" :@"12214"];
	
	newPatId = [self createPatient:@"Helen":@"Louise":@"Herron":@"6/2/1961":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Norman Bethune": physicianObj.physicianNpi :@"205" :@"12215"];
	
	newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Theodor Billroth": physicianObj.physicianNpi :@"206" :@"12216"];
	
	newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Guy de Chauliac": physicianObj.physicianNpi :@"207" :@"12217"];
	
	newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianObj.physicianNpi :@"207" :@"12217"];
	
	newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];
	
	newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"William Osler Abbott": physicianObj.physicianNpi :@"2007" :@"12213"];
	
	newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];
	
	newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];
	
	newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"2007" :@"12213"];
	
	newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"206" :@"12213"];
	
	newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianObj.physicianNpi :@"207" :@"12213"];
	
	newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Salvador Mazza": physicianObj.physicianNpi :@"2000" :@"12213"];
	
	newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"209" :@"12213"];
	
	newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Girolamo Fracastoro": physicianObj.physicianNpi :@"2007" :@"12213"];
	
	newPatId = [self createPatient:@"Rutherford":@"B.":@"Hayes":@"10/04/1922":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Girolamo Fracastoro": physicianObj.physicianNpi :@"201" :@"12213"];
	
	newPatId = [self createPatient:@"Ellen":@"Lewis":@"Herndon":@"8/30/1937":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"202" :@"12213"];
	
	newPatId = [self createPatient:@"Frances":@"Clara":@"Folsom":@"7/21/1964":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"203" :@"12213"];
	
	newPatId = [self createPatient:@"Ida":@"":@"Saxton":@"6/8/1947":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Leo Kanner": physicianObj.physicianNpi :@"200" :@"12213"];
	
	newPatId = [self createPatient:@"Edith":@"Kermit":@"Carow":@"8/6/1961":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"204" :@"12213"];
	
	newPatId = [self createPatient:@"Jacqueline":@"Lee":@"Bouvier":@"7/28/1929":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"205" :@"12213"];
	
	newPatId = [self createPatient:@"Claudia":@"Alta":@"Taylor":@"12/22/1912":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"110" :@"12213"];
	
	newPatId = [self createPatient:@"Thelma":@"Catherine":@"Ryan":@"3/16/1912":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"100" :@"12213"];
	
	newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"100" :@"12213"];
	
	newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"400" :@"12213"];
	
	newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"600" :@"12213"];
	
	newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"700" :@"12213"];
	//[pool release];
	[format release];
	[facility release];
	 */
}

- (void) addMyCharges
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	/*
	NSError *error=nil;
	NSString *username = [QliqKeychainUtils getItemForKey:KS_KEY_USERNAME error:&error];
	Physician *physicianObj = [Physician getPhysician:username];
	
	NSMutableArray *censusArray = [Census getActiveCensusObjects:physicianObj.physicianNpi andBtnPressed:@"Me"];
	for(Census *censusObj in censusArray){
		[self createChargesForThisPatient:censusObj.censusId :physicianObj.physicianNpi];
	}*/
	//[pool release];
}

- (void) createGroupRounds
{
	/*
	physicianNpi = [self createPhysician:meObj.groupId:@"John Snow":@"JS":@"Anesthesiology":@"js@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Theodor Billroth": physicianNpi :@"206" :@"12216"];
	
	newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Guy de Chauliac": physicianNpi :@"207" :@"12217"];
	
	facility.name = @"Johns Hopkins Hospital";
	facilityNpi = [Facility getFacilityId:facility];
	newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianNpi :@"207" :@"12217"];
	
	physicianNpi = [self createPhysician:meObj.groupId:@"Christiaan Barnard":@"CB":@"Cardiology":@"cb@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"William Osler Abbott": physicianNpi :@"2007" :@"12213"];

	facility.name = @"Memorial Sloan-Kettering";
	facilityNpi = [Facility getFacilityId:facility];
	newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];
	
	newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];

	facility.name = @"Walter Reed Army Medical Center";
	facilityNpi = [Facility getFacilityId:facility];
	newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];

	newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"206" :@"12213"];
	
	physicianNpi = [self createPhysician:meObj.groupId:@"Rene Theophile Laennec":@"RTL":@"Cardiology":@"rtl@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianNpi :@"207" :@"12213"];

	newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Salvador Mazza": physicianNpi :@"2000" :@"12213"];
	
	newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"209" :@"12213"];

	facility.name = @"Albert Einstein Medical Center";
	facilityNpi = [Facility getFacilityId:facility];
	newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Girolamo Fracastoro": physicianNpi :@"2007" :@"12213"];
	
	physicianNpi = [self createPhysician:meObj.groupId:@"Helen B. Taussig":@"HBT":@"Cardiology":@"hbt@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	facility.name = @"M.D. Anderson";
	facilityNpi = [Facility getFacilityId:facility];
	newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"100" :@"12213"];

	newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"400" :@"12213"];
	
	physicianNpi = [self createPhysician:meObj.groupId:@"Allen Oldfather Whipple":@"AOW":@"Oncology":@"aow@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"600" :@"12213"];

	facility.name = @"Mount Sinai Medical Center";
	facilityNpi = [Facility getFacilityId:facility];
	newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"700" :@"12213"];
	[facility release];*/
}
/*
- (void) addGroupCharges
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *error=nil;
	NSString *username = [QliqKeychainUtils getItemForKey:KS_KEY_USERNAME error:&error];
	Physician *physicianObj = [Physician getPhysician:username];
	
	NSMutableArray *censusArray = [Census getActiveCensusObjects:physicianObj.physicianNpi andBtnPressed:@"Group"];
	for(Census *censusObj in censusArray){
		[self createChargesForThisPatient:censusObj.censusId :physicianObj.physicianNpi];
	}
	//[pool release];
}

- (void) createRounds
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Do work here
	[Physician deleteAllCharges];
	
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"MM/dd/yyyy"];
    [format setTimeZone:[NSTimeZone localTimeZone]];
	
	
	 NSString *username=nil;
	 username= [Helper getUsername];
	 
	 NSArray* splits = [username componentsSeparatedByString: @"@"];
	 NSString* qliqId = [splits objectAtIndex:0];
	 NSLog(@"qliqId: %@", qliqId);
	 
	NSInteger npi = 9000;
	
	//Create referring physicians
	ReferringPhysician *thisRefPhysician = [[ReferringPhysician alloc] init];
	thisRefPhysician.name = @"Mason Andrews";
	thisRefPhysician.specialty=@"Ob-Gyn";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi];
	NSInteger refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Virginia Apgar";
	thisRefPhysician.specialty=@"Anesthesiology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"William Stewart Agras";
	thisRefPhysician.specialty=@"Endocrinology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Frederick Banting";
	thisRefPhysician.specialty=@"Endocrinology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Christiaan Barnard";
	thisRefPhysician.specialty=@"Cardiology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Charles Best";
	thisRefPhysician.specialty=@"Endocrinology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Norman Bethune";
	thisRefPhysician.specialty=@"Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Theodor Billroth";
	thisRefPhysician.specialty=@"Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Alfred Blalock";
	thisRefPhysician.specialty = @"Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Jean-Martin Charcot";
	thisRefPhysician.specialty = @"Neurology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Guy de Chauliac";
	thisRefPhysician.specialty = @"Family Medicine";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Harvey Cushing";
	thisRefPhysician.specialty = @"Neuro Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Salvador Mazza";
	thisRefPhysician.specialty = @"Infectious Diseases";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Jean Astruc";
	thisRefPhysician.specialty = @"Infectious Diseases";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Charles R. Drew";
	thisRefPhysician.specialty = @"Transplant Medicine";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Helen Flanders Dunbar";
	thisRefPhysician.specialty = @"Psychology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Christian Eijkman";
	thisRefPhysician.specialty = @"Pathology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"William Osler Abbott";
	thisRefPhysician.specialty = @"Pathology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Girolamo Fracastoro";
	thisRefPhysician.specialty = @"Pathology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Sigmund Freud";
	thisRefPhysician.specialty = @"Psychiatry";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Daniel Carleton Gajdusek";
	thisRefPhysician.specialty = @"Neurology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Henry Gray";
	thisRefPhysician.specialty = @"Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Orvan Hess";
	thisRefPhysician.specialty = @"OBGYN";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"John Hunter";
	thisRefPhysician.specialty = @"Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Elliott P. Joslin";
	thisRefPhysician.specialty = @"Endocrinology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Edward Jenner";
	thisRefPhysician.specialty = @"Infectious Diseases";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Leo Kanner";
	thisRefPhysician.specialty = @"Psychiatry";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Seymour Kety";
	thisRefPhysician.specialty = @"Neurology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Theodor Kocher";
	thisRefPhysician.specialty = @"Endocrinology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Rene Theophile Laennec";
	thisRefPhysician.specialty = @"Cardiology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Joseph Lister";
	thisRefPhysician.specialty = @"Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"George Richards Minot";
	thisRefPhysician.specialty = @"Pathology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Herbert Needleman";
	thisRefPhysician.specialty = @"Pathology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"William Osler";
	thisRefPhysician.specialty = @"Family Medicine";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Wilder Penfield";
	thisRefPhysician.specialty = @"Neurology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Joseph Ransohoff";
	thisRefPhysician.specialty = @"Neuro Surgery";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Jonas Salk";
	thisRefPhysician.specialty = @"Infectious Diseases";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"John Snow";
	thisRefPhysician.specialty = @"Anesthesiology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Andrew Taylor Still";
	thisRefPhysician.specialty = @"General Practice";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Thomas Sydenham";
	thisRefPhysician.specialty = @"Family Medicine";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Helen B. Taussig";
	thisRefPhysician.specialty = @"Cardiology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Rudolf Virchow";
	thisRefPhysician.specialty = @"Pathology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Allen Oldfather Whipple";
	thisRefPhysician.specialty = @"Oncology";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	thisRefPhysician.name = @"Priscilla White";
	thisRefPhysician.specialty = @"OBGYN";
	thisRefPhysician.npi= [NSString stringWithFormat:@"%d",npi++];
	refPhysicianId = [ReferringPhysician addReferringPhysician:thisRefPhysician];
	
	
	 NSInteger newPatId=0;
	 newPatId = [self createPatient:@"George":@"":@"Washington":@"02/22/1932":@"Male":@"White"];
	 newPatId = [self createPatient:@"John":@"":@"Adams":@"10/30/1935":@"Male":@"White"];
	 newPatId = [self createPatient:@"Martha":@"":@"Dandridge":@"6/2/1931":@"Female":@"White"];
	 newPatId = [self createPatient:@"Lucy":@"Ware":@"Webb":@"8/28/1931":@"Female":@"White"];
	 newPatId = [self createPatient:@"Lucretia":@"":@"Rudolph":@"4/19/1932":@"Female":@"White"];
	 newPatId = [self createPatient:@"Helen":@"Louise":@"Herron":@"6/2/1961":@"Female":@"White"];
	 newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	 newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	 newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	 newPatId = [self createPatient:@"John":@"Quincy":@"Adams":@"07/11/1967":@"Male":@"White"];
	 newPatId = [self createPatient:@"Andrew":@"":@"Jackson":@"03/15/1967":@"Male":@"White"];
	 newPatId = [self createPatient:@"Van Buren":@"":@"Martin":@"12/05/1982":@"Male":@"White"];
	 newPatId = [self createPatient:@"William":@"Henry":@"Harrison":@"02/01/1973":@"Male":@"White"];
	 newPatId = [self createPatient:@"John":@"":@"Tyler":@"03/29/1990":@"Male":@"White"];
	 newPatId = [self createPatient:@"James":@"K.":@"Polk":@"11/02/1995":@"Male":@"White"];
	 newPatId = [self createPatient:@"Abigail":@"":@"Smith":@"11/11/1944":@"Female":@"White"];
	 newPatId = [self createPatient:@"Martha":@"":@"Wayles":@"10/30/1948":@"Female":@"White"];
	 newPatId = [self createPatient:@"Dolley":@"":@"Payne":@"5/20/1968":@"Female":@"White"];
	 newPatId = [self createPatient:@"Elizabeth":@"":@"Kortright":@"6/30/1968":@"Female":@"White"];
	 newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	 newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	 newPatId = [self createPatient:@"Franklin":@"":@"Pierce":@"11/23/2004":@"Male":@"White"];
	 newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	 newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	 newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	 newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	 newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	 newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	 newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	 newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	 newPatId = [self createPatient:@"Rutherford":@"B.":@"Hayes":@"10/04/1922":@"Male":@"White"];
	 newPatId = [self createPatient:@"Ellen":@"Lewis":@"Herndon":@"8/30/1937":@"Female":@"White"];
	 newPatId = [self createPatient:@"Frances":@"Clara":@"Folsom":@"7/21/1964":@"Female":@"White"];
	 newPatId = [self createPatient:@"Ida":@"":@"Saxton":@"6/8/1947":@"Female":@"White"];
	 newPatId = [self createPatient:@"Edith":@"Kermit":@"Carow":@"8/6/1961":@"Female":@"White"];
	 newPatId = [self createPatient:@"Jacqueline":@"Lee":@"Bouvier":@"7/28/1929":@"Female":@"White"];
	 newPatId = [self createPatient:@"Claudia":@"Alta":@"Taylor":@"12/22/1912":@"Female":@"White"];
	 newPatId = [self createPatient:@"Thelma":@"Catherine":@"Ryan":@"3/16/1912":@"Female":@"White"];
	 newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	 newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	 newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	 newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	 
	
	Facility *facility = [[Facility alloc] init];
	//NSInteger groupId = 0;
	double facilityNpi=0;
	NSInteger newPatId=0;
	NSInteger newCensusId=0;
	
	facilityNpi = [self createFacility:@"M.D. Anderson":@"Hospital"];
	facilityNpi = [self createFacility:@"Memorial Sloan-Kettering":@"Hospital"];
	facilityNpi = [self createFacility:@"Johns Hopkins Hospital":@"Hospital"];
	facilityNpi = [self createFacility:@"Cleveland Clinic":@"Hospital"];
	facilityNpi = [self createFacility:@"Mayo Clinic":@"Hospital"];
	facilityNpi = [self createFacility:@"Massachusetts General Hospital":@"Hospital"];
	facilityNpi = [self createFacility:@"University of Pittsburgh Medical Center":@"Hospital"];
	facilityNpi = [self createFacility:@"Mount Sinai Medical Center":@"Hospital"];
	facilityNpi = [self createFacility:@"Brigham and Women's Hospital":@"Hospital"];
	facilityNpi = [self createFacility:@"UCLA Medical Center":@"Hospital"];
	facilityNpi = [self createFacility:@"Walter Reed Army Medical Center":@"Hospital"];
	facilityNpi = [self createFacility:@"Albert Einstein Medical Center":@"Hospital"];
	
	NSError *error=nil;
	NSString *username = [QliqKeychainUtils getItemForKey:KS_KEY_USERNAME error:&error];
	Physician *physicianObj = [Physician getPhysician:username];
	
	
	//groupId = [self createPhysicianGroup:@"Hoover Dam Cardiologists Inc."];
	
	//physicianNpi = [self createPhysician:groupId:@"Virginia Apgar":@"VA":@"Anesthesiology":@"va@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	
	facility.name = @"M.D. Anderson";
	facilityNpi = [Facility getFacilityId:facility];
	newPatId = [self createPatient:@"George":@"":@"Washington":@"02/22/1932":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"200" :@"12213"];
	//[self createChargesForThisPatient:newCensusId: physicianNpi];
	
	newPatId = [self createPatient:@"John":@"":@"Adams":@"10/30/1935":@"Male":@"White"];
	newCensusId = [self createCensus:newPatId: facilityNpi :@"William Stewart Agras": physicianObj.physicianNpi :@"201" :@"12211"];
	//[self createChargesForThisPatient:newCensusId: physicianNpi];
	
	 newPatId = [self createPatient:@"Martha":@"":@"Dandridge":@"6/2/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Frederick Banting": physicianObj.physicianNpi :@"202" :@"12212"];
	 //[self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 newPatId = [self createPatient:@"Lucy":@"Ware":@"Webb":@"8/28/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Charles Best": physicianObj.physicianNpi :@"203" :@"12213"];
	 //[self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lucretia":@"":@"Rudolph":@"4/19/1932":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianObj.physicianNpi :@"204" :@"12214"];
	 //[self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 newPatId = [self createPatient:@"Helen":@"Louise":@"Herron":@"6/2/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Norman Bethune": physicianObj.physicianNpi :@"205" :@"12215"];
	 //[self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 //physicianNpi = [self createPhysician:groupId:@"John Snow":@"JS":@"Anesthesiology":@"js@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	 newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Theodor Billroth": physicianObj.physicianNpi :@"206" :@"12216"];
	 //[self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Guy de Chauliac": physicianObj.physicianNpi :@"207" :@"12217"];
	 //[self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 facility.name = @"Johns Hopkins Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianObj.physicianNpi :@"207" :@"12217"];
	 //[self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 
	 physicianNpi = [self createPhysician:groupId:@"Christiaan Barnard":@"CB":@"Cardiology":@"cb@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	 newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"William Osler Abbott": physicianNpi :@"2007" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Franklin":@"":@"Pierce":@"11/23/2004":@"Male":@"White"];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Walter Reed Army Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2007" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"206" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Rene Theophile Laennec":@"RTL":@"Cardiology":@"rtl@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	 newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Harvey Cushing": physicianNpi :@"207" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Salvador Mazza": physicianNpi :@"2000" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"209" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Albert Einstein Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Girolamo Fracastoro": physicianNpi :@"2007" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Rutherford":@"B.":@"Hayes":@"10/04/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Girolamo Fracastoro": physicianNpi :@"201" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ellen":@"Lewis":@"Herndon":@"8/30/1937":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"202" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Frances":@"Clara":@"Folsom":@"7/21/1964":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"203" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ida":@"":@"Saxton":@"6/8/1947":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Leo Kanner": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mayo Clinic";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Edith":@"Kermit":@"Carow":@"8/6/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"204" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jacqueline":@"Lee":@"Bouvier":@"7/28/1929":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"205" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"University of Pittsburgh Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Claudia":@"Alta":@"Taylor":@"12/22/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"110" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Thelma":@"Catherine":@"Ryan":@"3/16/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"100" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Helen B. Taussig":@"HBT":@"Cardiology":@"hbt@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	 facility.name = @"M.D. Anderson";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"100" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"400" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Allen Oldfather Whipple":@"AOW":@"Oncology":@"aow@qliqsoft.com":[NSString stringWithFormat:@"%d",npi++]];
	 newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"600" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mount Sinai Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"700" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 groupId = [self createPhysicianGroup:@"Monticello Family Practice"];
	 
	 physicianNpi = [self createPhysician:groupId:@"Guy de Chauliac":@"GD":@"Family Medicine":@"gd@qliqsoft.com"];
	 facility.name = @"M.D. Anderson";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"George":@"":@"Washington":@"02/22/1932":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"202" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"John":@"":@"Adams":@"10/30/1935":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"204" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Martha":@"":@"Dandridge":@"6/2/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"205" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Lucy":@"Ware":@"Webb":@"8/28/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"201" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lucretia":@"":@"Rudolph":@"4/19/1932":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"100" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Helen":@"Louise":@"Herron":@"6/2/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"120" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"William Osler":@"WO":@"Family Medicine":@"wo@qliqsoft.com"];
	 newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"300" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"400" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Johns Hopkins Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"500" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Thomas Sydenham":@"TS":@"Family Medicine":@"ts@qliqsoft.com"];
	 newPatId = [self createPatient:@"John":@"Quincy":@"Adams":@"07/11/1967":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"500" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Andrew":@"":@"Jackson":@"03/15/1967":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"505" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Van Buren":@"":@"Martin":@"12/05/1982":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"300" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"William":@"Henry":@"Harrison":@"02/01/1973":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"300" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"John":@"":@"Tyler":@"03/29/1990":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"400" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Massachusetts General Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"James":@"K.":@"Polk":@"11/02/1995":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"500" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Abigail":@"":@"Smith":@"11/11/1944":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"600" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Brigham and Women's Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Martha":@"":@"Wayles":@"10/30/1948":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"700" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Dolley":@"":@"Payne":@"5/20/1968":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"700" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Elizabeth":@"":@"Kortright":@"6/30/1968":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"300" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Andrew Taylor Still":@"ATS":@"General Practice":@"ats@qliqsoft.com"];
	 newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"400" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"500" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Franklin":@"":@"Pierce":@"11/23/2004":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"650" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"600" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"206" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Walter Reed Army Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"206" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2040" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Christian Eijkman":@"CE":@"Pathology":@"ce@qliqsoft.com"];
	 newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2030" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2020" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2020" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Walter Reed Army Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2030" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Rutherford":@"B.":@"Hayes":@"10/04/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"300" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ellen":@"Lewis":@"Herndon":@"8/30/1937":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Frances":@"Clara":@"Folsom":@"7/21/1964":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2002" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ida":@"":@"Saxton":@"6/8/1947":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2002" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mayo Clinic";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Edith":@"Kermit":@"Carow":@"8/6/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2002" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jacqueline":@"Lee":@"Bouvier":@"7/28/1929":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2002" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"University of Pittsburgh Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Claudia":@"Alta":@"Taylor":@"12/22/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2004" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Thelma":@"Catherine":@"Ryan":@"3/16/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2005" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"William Osler Abbott":@"WOA":@"Pathology":@"woa@qliqsoft.com"];
	 facility.name = @"M.D. Anderson";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2006" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Girolamo Fracastoro":@"GF":@"Pathology":@"gf@qliqsoft.com"];
	 newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2006" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mount Sinai Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"2004" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 
	 
	 groupId = [self createPhysicianGroup:@"Mount Rushmore Urgent Care"];
	 
	 physicianNpi = [self createPhysician:groupId:@"Harvey Cushing":@"HC":@"Neuro Surgery":@"hc@qliqsoft.com"];
	 facility.name = @"M.D. Anderson";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"George":@"":@"Washington":@"02/22/1932":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"John":@"":@"Adams":@"10/30/1935":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Martha":@"":@"Dandridge":@"6/2/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Lucy":@"Ware":@"Webb":@"8/28/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lucretia":@"":@"Rudolph":@"4/19/1932":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Helen":@"Louise":@"Herron":@"6/2/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Joseph Ransohoff":@"JR":@"Neuro Surgery":@"jr@qliqsoft.com"];
	 newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Johns Hopkins Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Jean-Martin Charcot":@"JC":@"Neurology":@"jc@qliqsoft.com"];
	 newPatId = [self createPatient:@"John":@"Quincy":@"Adams":@"07/11/1967":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Andrew":@"":@"Jackson":@"03/15/1967":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Van Buren":@"":@"Martin":@"12/05/1982":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"William":@"Henry":@"Harrison":@"02/01/1973":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"John":@"":@"Tyler":@"03/29/1990":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Massachusetts General Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"James":@"K.":@"Polk":@"11/02/1995":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Abigail":@"":@"Smith":@"11/11/1944":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Brigham and Women's Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Martha":@"":@"Wayles":@"10/30/1948":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Dolley":@"":@"Payne":@"5/20/1968":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Elizabeth":@"":@"Kortright":@"6/30/1968":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Daniel Carleton Gajdusek":@"DCG":@"Neurology":@"dcg@qliqsoft.com"];
	 newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Franklin":@"":@"Pierce":@"11/23/2004":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Walter Reed Army Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Seymour Kety":@"SK":@"Neurology":@"sk@qliqsoft.com"];
	 newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Walter Reed Army Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Rutherford":@"B.":@"Hayes":@"10/04/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ellen":@"Lewis":@"Herndon":@"8/30/1937":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Frances":@"Clara":@"Folsom":@"7/21/1964":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ida":@"":@"Saxton":@"6/8/1947":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mayo Clinic";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Edith":@"Kermit":@"Carow":@"8/6/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jacqueline":@"Lee":@"Bouvier":@"7/28/1929":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"University of Pittsburgh Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Claudia":@"Alta":@"Taylor":@"12/22/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Thelma":@"Catherine":@"Ryan":@"3/16/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Wilder Penfield":@"WP":@"Neurology":@"wp@qliqsoft.com"];
	 facility.name = @"M.D. Anderson";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	 newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	 
	 physicianNpi = [self createPhysician:groupId:@"Sigmund Freud":@"SF":@"Psychiatry":@"sf@qliqsoft.com"];
	 newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mount Sinai Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Leo Kanner":@"LK":@"Psychiatry":@"lk@qliqsoft.com"];
	 facility.name = @"Cleveland Clinic";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Herbert":@"Clark":@"Hoover":@"08/10/1974":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Helen Flanders Dunbar":@"HFD":@"Psychology":@"hfd@qliqsoft.com"];
	 facility.name = @"Cleveland Clinic";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Franklin":@"Delano":@"Roosevelt":@"01/30/1982":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 
	 
	 groupId = [self createPhysicianGroup:@"Watergate Clinic"];
	 
	 physicianNpi = [self createPhysician:groupId:@"Salvador Mazza":@"SM":@"Infectious Diseases":@"sm@qliqsoft.com"];
	 facility.name = @"M.D. Anderson";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"George":@"":@"Washington":@"02/22/1932":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"John":@"":@"Adams":@"10/30/1935":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Martha":@"":@"Dandridge":@"6/2/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Lucy":@"Ware":@"Webb":@"8/28/1931":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lucretia":@"":@"Rudolph":@"4/19/1932":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Helen":@"Louise":@"Herron":@"6/2/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Jean Astruc":@"JA":@"Infectious Diseases":@"ja@qliqsoft.com"];
	 newPatId = [self createPatient:@"Thomas":@"":@"Jefferson":@"04/13/1943":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"James":@"":@"Madison":@"03/16/1951":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Johns Hopkins Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"James":@"":@"Monroe":@"04/28/1958":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Edward Jenner":@"EJ":@"Infectious Diseases":@"ej@qliqsoft.com"];
	 newPatId = [self createPatient:@"John":@"Quincy":@"Adams":@"07/11/1967":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Andrew":@"":@"Jackson":@"03/15/1967":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Van Buren":@"":@"Martin":@"12/05/1982":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"William":@"Henry":@"Harrison":@"02/01/1973":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"John":@"":@"Tyler":@"03/29/1990":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Massachusetts General Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"James":@"K.":@"Polk":@"11/02/1995":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Abigail":@"":@"Smith":@"11/11/1944":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Brigham and Women's Hospital";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Martha":@"":@"Wayles":@"10/30/1948":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Dolley":@"":@"Payne":@"5/20/1968":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Elizabeth":@"":@"Kortright":@"6/30/1968":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Jonas Salk":@"JS":@"Infectious Diseases":@"js@qliqsoft.com"];
	 newPatId = [self createPatient:@"Zachary":@"":@"Taylor":@"11/24/1984":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Millard":@"":@"Fillmore":@"01/07/2000":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Franklin":@"":@"Pierce":@"11/23/2004":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Abigail":@"":@"Powers":@"3/13/1998":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jane":@"Means":@"Appleton":@"3/12/2006":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Walter Reed Army Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Mary":@"Ann":@"Todd":@"12/13/1918":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Eliza":@"":@"McCardle":@"10/4/2010":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"George Richards Minot":@"GRM":@"Pathology":@"grm@qliqsoft.com"];
	 newPatId = [self createPatient:@"James":@"":@"Buchanan":@"04/23/1991":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Abraham":@"":@"Lincoln":@"02/12/2009":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Andrew":@"":@"Johnson":@"12/29/2008":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Walter Reed Army Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Ulysses":@"S.":@"Grant":@"04/27/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Rutherford":@"B.":@"Hayes":@"10/04/1922":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ellen":@"Lewis":@"Herndon":@"8/30/1937":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Memorial Sloan-Kettering";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Frances":@"Clara":@"Folsom":@"7/21/1964":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Ida":@"":@"Saxton":@"6/8/1947":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mayo Clinic";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Edith":@"Kermit":@"Carow":@"8/6/1961":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Jacqueline":@"Lee":@"Bouvier":@"7/28/1929":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"University of Pittsburgh Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Claudia":@"Alta":@"Taylor":@"12/22/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Thelma":@"Catherine":@"Ryan":@"3/16/1912":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Herbert Needleman":@"HN":@"Pathology":@"hn@qliqsoft.com"];
	 facility.name = @"M.D. Anderson";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"Lou":@"":@"Henry":@"3/29/1974":@"Female":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 newPatId = [self createPatient:@"Lyndon":@"Baines":@"Johnson":@"08/27/2008":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 
	 physicianNpi = [self createPhysician:groupId:@"Rudolf Virchow":@"RV":@"Pathology":@"rv@qliqsoft.com"];
	 newPatId = [self createPatient:@"Dwight":@"David":@"Eisenhower":@"10/14/1990":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	 facility.name = @"Mount Sinai Medical Center";
	 facilityNpi = [Facility getFacilityId:facility];
	 newPatId = [self createPatient:@"John":@"Fitzgerald":@"Kennedy":@"05/29/1917":@"Male":@"White"];
	 newCensusId = [self createCensus:newPatId: facilityNpi :@"Helen B. Taussig": physicianNpi :@"200" :@"12213"];
	 [self createChargesForThisPatient:newCensusId: physicianNpi];
	
	
	//[pool drain];
	
}
- (void) createCharges
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *error=nil;
	NSString *username = [QliqKeychainUtils getItemForKey:KS_KEY_USERNAME error:&error];
	Physician *physicianObj = [Physician getPhysician:username];
	
	NSMutableArray *censusArray = [Census getActiveCensusObjects:physicianObj.physicianNpi andBtnPressed:@"Me"];
	for(Census *censusObj in censusArray){
		[self createChargesForThisPatient:censusObj.censusId :physicianObj.physicianNpi];
	}
	
	//[pool drain];
	
} 

- (void) createChargesForThisPatient:(NSInteger)newCensusId:(double) physicianNpi
{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	// create a calendar
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	for(int j=0;j<=2;j++){
		[components setDay:-j];
		NSDate *newDate2 = [gregorian dateByAddingComponents:components toDate:[NSDate dateWithoutTime] options:0];
		
		Encounter_old *newencounter = [[Encounter_old alloc] init];
		newencounter.censusId = newCensusId;
		newencounter.dateOfService = [newDate2 timeIntervalSince1970];
		newencounter.status=EncounterStatusVisit;
		//newencounter.attendingPhysicianId=physicianNpi;
		newencounter.status = EncounterStatusWIP;
		NSInteger newEnId = [Encounter_old addEncounter:newencounter];
		[newencounter release];
		[Encounter_old updateEncounterLastUpdated:newEnId];
		
		for(int k=0;k<2;k++){
			EncounterCpt *newEnCpt = [[EncounterCpt alloc] init];
			newEnCpt.encounterId = newEnId;
			if(k==0)
				newEnCpt.cptCode = @"99221";
			if(k==1)
				newEnCpt.cptCode = @"11719";

			newEnCpt.status = EncounterStatusComplete;
			newEnCpt.createdAt = [[NSDate date] timeIntervalSince1970];
			newEnCpt.createdUser = [Helper getUsername];
			NSInteger newEnCptId = [EncounterCpt addEncounterCpt:newEnCpt];
			[newEnCpt release];
			
			for(int l=0;l<2;l++){
				EncounterIcd *newEnIcd = [[EncounterIcd alloc] init];
				newEnIcd.encounterCptId = newEnCptId;
				
				if(l==0){
					newEnIcd.icdCode = @"032.82";
					newEnIcd.isPrimary=TRUE;
				}else{ 
					newEnIcd.icdCode = @"047.9";
					newEnIcd.isPrimary=FALSE;
				}
				newEnIcd.status = EncounterStatusComplete;
				[EncounterIcd addEncounterIcd:newEnIcd];
				[newEnIcd release];
			}	
			
			for(int m=0;m<2;m++){
				EncounterCptModifier *newEnMod = [[EncounterCptModifier alloc] init];
				newEnMod.encounterCptId=newEnCptId;
				newEnMod.status = EncounterStatusComplete;
				newEnMod.modifier = [NSString stringWithFormat:@"%d",21+m];
				[EncounterCptModifier addEncounterCptModifier:newEnMod];
				[newEnMod release];
			}				
			
		}			
		
	}
	[components release];
	[gregorian release];
}

- (NSInteger) createPhysician:(NSInteger) groupId:(NSString *) name:(NSString *)initials:(NSString*) specialty:(NSString*) email:(double) npi
{
	//Create physicians in this group
	Physician *thisPhysician = [[Physician alloc] init];
	thisPhysician.groupId=groupId;
	thisPhysician.name = name;
	thisPhysician.initials=initials;
	thisPhysician.email=email;
	//thisPhysician.npi=npi;
	double physicianNpi = [Physician addPhysician:thisPhysician];
	[thisPhysician release];
	return physicianNpi;
}

- (NSInteger) createPatient:(NSString *)fn:(NSString*)mn:(NSString*)ln:(NSString *)dob:(NSString*)gender:(NSString*)race
{
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"MM/dd/yyyy"];
    [format setTimeZone:[NSTimeZone localTimeZone]];
	
	Patient_old *newpat = [[Patient_old alloc] init];
	newpat.firstName = fn;
	newpat.middleName = mn;
	newpat.lastName = ln;
	newpat.dateOfBirth = [[format dateFromString:dob] timeIntervalSince1970];
	newpat.gender=gender;
	newpat.race=race;
	NSInteger newPatId = [Patient_old addPatient:newpat];
	[newpat release];
	return newPatId;
}

- (NSInteger) createCensus:(NSInteger)newPatId:(double) facilityNpi:(NSString*)rphName:(double) physicianNpi:(NSString *)room:(NSString*)mrn
{
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	// create a calendar
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	[components setDay:-5];
	NSDate *newDate2 = [gregorian dateByAddingComponents:components toDate:[NSDate dateWithoutTime] options:0];
	
	Census *newcensus = [[Census alloc] init];
	newcensus.patientId = newPatId;
	newcensus.facilityNpi = facilityNpi;
	newcensus.admitDate = [newDate2 timeIntervalSince1970];
	ReferringPhysician *refPhysician = [[ReferringPhysician alloc] init];
	refPhysician.name = rphName;
	NSInteger refRphId = [ReferringPhysician getReferringPhysicianId:refPhysician];
	newcensus.referringPhysicianNpi = refRphId;
	newcensus.physicianNpi = physicianNpi;	
	newcensus.room=room;
	newcensus.mrn=mrn;
	newcensus.active=1;
	newcensus.censusType=NonConsult;
	NSInteger newCensusId = [Census addPatientToCensus:newcensus];
	[refPhysician release];
	[newcensus release];
	
	return newCensusId;
}

- (NSInteger) createFacility:(NSString *) name:(NSString *)type
{
	NSString *username = [Helper getUsername];
	Physician *physicianObj = [Physician getPhysician:username];

	Facility_old *thisFacility = [[Facility_old alloc] init];
	thisFacility.name=name;
	thisFacility.facilityTypeId=[FacilityType getFacilityTypePk:type];
	double facilityNpi = [Facility_old addFacility:thisFacility andPhysicianId:physicianObj.physicianNpi];
	[thisFacility release];
	return facilityNpi;
}
- (NSInteger) createPhysicianGroup:(NSString *) name
{
	//Create the physician group
	PhysicianGroup *thisGroup = [[PhysicianGroup alloc] init];
	thisGroup.name= name;
	NSInteger groupId = [PhysicianGroup addPhysicianGroup:thisGroup];
	[thisGroup release];
	return groupId;
}

*/
@end
