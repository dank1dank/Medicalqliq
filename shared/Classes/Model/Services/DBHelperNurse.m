//
//  DBHelperNurse.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/29/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "DBHelperNurse.h"
#import "DBUtil.h"
#import "Helper.h"


@implementation DBHelperNurse

+ (User *) getUser:(NSString *)username
{
	NSMutableString *selectUserQuery = [NSMutableString stringWithString:@""];
	
    [selectUserQuery appendString:@"SELECT "
	 " user_id, "
	 " role "
	 " FROM user_role "
	 " WHERE user_id = ?"];
	
	FMResultSet *user_rs = [[DBUtil sharedDBConnection]  executeQuery:selectUserQuery,username];
	User *userObj = [[[User alloc] init] autorelease];
	while ([user_rs next])
	{
		NSString *strRole = [user_rs stringForColumn:@"role"];
		//userObj.userName = [user_rs stringForColumn:@"user_id"];
		//userObj.role = [user_rs stringForColumn:@"role"];
		if([strRole isEqualToString:@"House Nurse"] ||
		   [strRole isEqualToString:@"Charge Nurse"] ||
		   [strRole isEqualToString:@"Floor Nurse"] ||
		   [strRole isEqualToString:@"Nurse Assistant"])
        {
			userObj.userName = [user_rs stringForColumn:@"user_id"];
			userObj.role = strRole;
			Nurse *nurseObj = [Nurse getNurseWithUsername:userObj.userName];
			userObj.facilityNpi = nurseObj.facilityNpi;
			userObj.facilityName = nurseObj.facilityName;
			userObj.name = nurseObj.name;
			userObj.useGroupName = FALSE;
		}
        else if([strRole isEqualToString:@"Charging"])
        {
			userObj.userName = [user_rs stringForColumn:@"user_id"];
			userObj.role = strRole;
			Physician *physicianObj = [Physician getPhysician:userObj.userName];
			userObj.useGroupName = TRUE;
			userObj.groupName = physicianObj.groupName;
			userObj.name = physicianObj.name;
			if(physicianObj.specialization != nil && [physicianObj.specialization length] > 0)
            {
				userObj.specialty = physicianObj.specialization;
            }
			else
            {
				userObj.specialty = physicianObj.classification;
            }
		}
	}
	[user_rs close];
	
	
	//after looping thru the result set, return the array
	return userObj;
}

+ (NSInteger) getRoleTypeId:(NSString *)role
{
	NSMutableString *selectUserRoleQuery = [NSMutableString stringWithString:@""];
	NSInteger role_type_id = 0;
	
    [selectUserRoleQuery appendString:@"SELECT "
	 " id as role_type_id "
	 " FROM role_type "
	 " WHERE role like '%?%'"];
	
	FMResultSet *role_type_rs = [[DBUtil sharedDBConnection]  executeQuery:selectUserRoleQuery,role];
	while ([role_type_rs next])
	{
		role_type_id = [role_type_rs intForColumn:@"role_type_id"];
	}
	[role_type_rs close];
	
	
	//after looping thru the result set, return the array
	return role_type_id;
}

//Floors List 
+ (NSInteger) addFloor: (Floor_old *)floor
{
    NSString *query = @"SELECT id FROM floor WHERE facility_npi = ? AND name = ?";
    FMResultSet *floor_rs = [[DBUtil sharedDBConnection]  executeQuery:query, floor.facilityNpi, floor.name, nil];

    NSInteger floorId = 0;
    if ([floor_rs next]) {
        floorId = [floor_rs intForColumnIndex:0];
    }
    [floor_rs close];
    
    if (floorId == 0) {
        query = @"INSERT INTO floor(facility_npi, name) VALUES (?, ?)";
        [[DBUtil sharedDBConnection] executeUpdate:query, floor.facilityNpi, floor.name, nil];
        floorId = [[DBUtil sharedDBConnection] lastInsertRowId];
    }
    
    return floorId;
}

+ (NSMutableArray *) getFloors:(NSString *)facilityNpi
{
	NSMutableArray *floorsArray = [[[NSMutableArray alloc] init] autorelease];
	NSMutableString *selectFloorsQuery = [NSMutableString stringWithString:@""];
	
    [selectFloorsQuery appendString:@"SELECT "
	 " id as floor_id, "
	 " name as floor_name "
	 " FROM floor "
	 " WHERE trim(facility_npi) = ?"];
	
	FMResultSet *floors_rs = [[DBUtil sharedDBConnection]  executeQuery:selectFloorsQuery,facilityNpi];
	
	while ([floors_rs next])
	{
		NSInteger primaryKey = [floors_rs intForColumn:@"floor_id"];
		Floor_old *floorObj = [[Floor_old alloc] initWithPrimaryKey:primaryKey];
		
		floorObj.name = [floors_rs stringForColumn:@"floor_name"];
		floorObj.facilityNpi = facilityNpi;
		
		[floorsArray addObject:floorObj];
		[floorObj release];
	}
	[floors_rs close];
	//after looping thru the result set, return the array
	return floorsArray;
}

+ (NSMutableArray *) getRooms:(NSInteger)floorId
{
	NSMutableArray *roomsArray = [[[NSMutableArray alloc] init] autorelease];
	NSMutableString *selectRoomsQuery = [NSMutableString stringWithString:@""];
	
    [selectRoomsQuery appendString:@"SELECT "
	 " id as room_id, "
	 " floor_id as floor_id, "
	 " room, "
	 " beds "
	 " FROM room "
	 " WHERE floor_id = ?"];
	
	FMResultSet *rooms_rs = [[DBUtil sharedDBConnection]  executeQuery:selectRoomsQuery,[NSNumber numberWithInt:floorId]];
	
	while ([rooms_rs next])
	{
		NSInteger primaryKey = [rooms_rs intForColumn:@"room_id"];
		Room *roomObj = [[Room alloc] initWithPrimaryKey:primaryKey];
		
		roomObj.floorId	= [rooms_rs intForColumn:@"floor_id"];
		roomObj.room = [rooms_rs stringForColumn:@"room"];
		roomObj.numberOfBeds =  [rooms_rs intForColumn:@"beds"];
		
		[roomsArray addObject:roomObj];
		[roomObj release];
	}
	[rooms_rs close];
	//after looping thru the result set, return the array
	return roomsArray;
}

+ (NSInteger) addRoom: (NSInteger)floorId: (Room *)room
{
    NSString *query = @"SELECT id FROM room WHERE floor_id = ? AND room = ?";
    FMResultSet *room_rs = [[DBUtil sharedDBConnection]  executeQuery:query, [NSNumber numberWithInt:floorId], room.room, nil];
    
    NSInteger roomId = 0;
    if ([room_rs next]) {
        roomId = [room_rs intForColumnIndex:0];
    }
    [room_rs close];
    
    if (roomId == 0) {
        query = @"INSERT INTO room(floor_id, room, beds) VALUES (?, ?, ?)";
        [[DBUtil sharedDBConnection] executeUpdate:query, [NSNumber numberWithInt:floorId], room.room, [NSNumber numberWithInt:room.numberOfBeds], nil];
        roomId = [[DBUtil sharedDBConnection] lastInsertRowId];
    } else {
        query = @"UPDATE room SET beds = ? WHERE id = ?";
        [[DBUtil sharedDBConnection] executeUpdate:query, [NSNumber numberWithInt:room.numberOfBeds], [NSNumber numberWithInt:roomId], nil];
    }
    
    return roomId;    
}

+ (void) deleteRoomsForFloor: (NSInteger)floorId
{
    [[DBUtil sharedDBConnection] executeQuery:@"DELETE FROM room WHERE floor_id = ?", [NSNumber numberWithInt:floorId]];
}

+ (void) deleteFloor: (NSInteger)floorId
{
    [[DBUtil sharedDBConnection] executeQuery:@"DELETE FROM floor WHERE id = ?", [NSNumber numberWithInt:floorId]];    
}

+ (void) deleteFloorsAndRooms
{
    [[DBUtil sharedDBConnection] executeQuery:@"DELETE FROM floor"];
    [[DBUtil sharedDBConnection] executeQuery:@"DELETE FROM room"];    
}

+ (NSMutableArray *) getPatientsInRoom:(NSString *)room
{
	NSMutableArray *patientsArray = [[[NSMutableArray alloc] init] autorelease];
	NSMutableString *selectPatientsQuery = [NSMutableString stringWithString:@""];
	
    [selectPatientsQuery appendString:@"SELECT "
	 " census.id as census_id, "
	 " patient.id as patient_id, "
	 " CASE WHEN length(middle_name)>0 THEN trim(last_name) ||', '||trim(first_name) ||' '||trim(middle_name) ELSE trim(last_name) ||', '||trim(first_name) END AS full_name, "	 
	 " patient.first_name, "
	 " patient.last_name, "
	 " patient.middle_name, "
	 " patient.gender "
	 " FROM census "
	 " INNER JOIN patient ON (census.patient_id = patient.id) "
	 " WHERE room = ?"];
	
	FMResultSet *patients_rs = [[DBUtil sharedDBConnection]  executeQuery:selectPatientsQuery,room];
	
	while ([patients_rs next])
	{
		NSInteger primaryKey = [patients_rs intForColumn:@"patient_id"];
		Patient_old *patientObj = [[Patient_old alloc] initWithPrimaryKey:primaryKey];
		patientObj.censusId = [patients_rs intForColumn:@"census_id"];
		patientObj.firstName = [patients_rs stringForColumn:@"first_name"];
		patientObj.lastName = [patients_rs stringForColumn:@"last_name"];
		patientObj.middleName = [patients_rs stringForColumn:@"middle_name"];
		patientObj.fullName = [patients_rs stringForColumn:@"full_name"];
		patientObj.gender = [patients_rs stringForColumn:@"gender"];
		[patientsArray addObject:patientObj];
		[patientObj release];
	}
	[patients_rs close];
	//after looping thru the result set, return the array
	return patientsArray;
}

+ (NSMutableArray *) getPatientsOnFloor:(NSInteger)floorId;
{
	NSMutableArray *patientsArray = [[[NSMutableArray alloc] init] autorelease];
	NSMutableString *selectPatientsQuery = [NSMutableString stringWithString:@""];
	
    [selectPatientsQuery appendString:@"SELECT "
	 " patient.id as patient_id, "
	 " census.id as census_id, "
	 " CASE WHEN length(middle_name)>0 THEN trim(last_name) ||', '||trim(first_name) ||' '||trim(middle_name) ELSE trim(last_name) ||', '||trim(first_name) END AS full_name, "	 
	 " patient.first_name, "
	 " patient.last_name, "
	 " patient.middle_name, "
	 " patient.gender "
	 " FROM census "
	 " INNER JOIN patient ON (census.patient_id = patient.id) "
	 " INNER JOIN room ON (census.room = room.room) "
	 " WHERE room.floor_id = ?"];
	NSLog(@"%@", selectPatientsQuery);
	
	FMResultSet *patients_rs = [[DBUtil sharedDBConnection]  executeQuery:selectPatientsQuery,[NSNumber numberWithInt:floorId]];
	
	while ([patients_rs next])
	{
		NSInteger primaryKey = [patients_rs intForColumn:@"patient_id"];
		Patient_old *patientObj = [[Patient_old alloc] initWithPrimaryKey:primaryKey];
		patientObj.censusId = [patients_rs intForColumn:@"census_id"];
		patientObj.firstName = [patients_rs stringForColumn:@"first_name"];
		patientObj.lastName = [patients_rs stringForColumn:@"last_name"];
		patientObj.middleName = [patients_rs stringForColumn:@"middle_name"];
		patientObj.fullName = [patients_rs stringForColumn:@"full_name"];
		patientObj.gender = [patients_rs stringForColumn:@"gender"];
		[patientsArray addObject:patientObj];
		[patientObj release];
	}
	[patients_rs close];
	//after looping thru the result set, return the array
	return patientsArray;
}

+ (Nurse *) getNurseWithUsername:(NSString *)userName
{	
	NSString *selectNurseQuery = @"SELECT "
	" nurse.id as nurse_id, "
	" nurse.npi as nurse_npi, "
	" nurse.facility_npi, "
	" facility.name as facility_name, "
	" nurse.name as nurse_name, "
	" nurse.initials, "
	" nurse.prefix, "
	" nurse.suffix, "
	" nurse.credentials, "
	" nurse.mobile, "
	" nurse.phone, "
	" nurse.fax, "
	" nurse.email, "
	" nurse.taxonomy_code, "
    " nurse.group_id as group_id "
	" FROM nurse "
	" INNER JOIN facility ON (nurse.facility_npi = facility.npi) "
	" WHERE trim(upper(nurse.email)) = trim(upper(?))";
	
	Nurse *nurseObj = nil;
	FMResultSet *nurse_rs = [[DBUtil sharedDBConnection] executeQuery:selectNurseQuery,userName];
	if ([nurse_rs next]) {
		NSString *primaryKey = [nurse_rs stringForColumn:@"nurse_id"];
		nurseObj = [[[Nurse alloc] init] autorelease];
		nurseObj.nurseId = primaryKey;
		nurseObj.nurseNpi = [nurse_rs stringForColumn:@"nurse_npi"];
		nurseObj.facilityNpi = [nurse_rs stringForColumn:@"facility_npi"];
		nurseObj.facilityName = [nurse_rs stringForColumn:@"facility_name"];
		nurseObj.name = [nurse_rs stringForColumn:@"nurse_name"];
		nurseObj.initials = [nurse_rs stringForColumn:@"initials"];
		nurseObj.prefix = [nurse_rs stringForColumn:@"prefix"];
		nurseObj.suffix = [nurse_rs stringForColumn:@"suffix"];
		nurseObj.mobile = [nurse_rs stringForColumn:@"mobile"];
		nurseObj.phone = [nurse_rs stringForColumn:@"phone"];
		nurseObj.fax = [nurse_rs stringForColumn:@"fax"];
		nurseObj.email = [nurse_rs stringForColumn:@"email"];
		nurseObj.credentials= [nurse_rs stringForColumn:@"credentials"];
		nurseObj.taxonomyCode	= [nurse_rs stringForColumn:@"taxonomy_code"];
        nurseObj.groupId = [nurse_rs intForColumn:@"group_id"];
	}
	return nurseObj;
}

+ (BOOL) addOrUpdateNurse:(Nurse *)nurseObj
{
	BOOL success=TRUE;
	NSString *nurseId = nil;
	
	//NURSE UPDATE/INSERT
	NSString *selectNurseQuery = @"SELECT "
	" id as nurse_id"
	" FROM nurse "
	" WHERE id = ?";
	FMResultSet *nurse_rs = [[DBUtil sharedDBConnection] executeQuery:selectNurseQuery,nurseObj.nurseId];
	BOOL recordFound=FALSE;
	while ([nurse_rs next]) {
		recordFound = TRUE;
		nurseId = [nurse_rs stringForColumn:@"nurse_id"];
	}
	
	//begin transation to lock the table while inserting
	[[DBUtil sharedDBConnection] beginTransaction];
	
	//update if recordFound otherwise insert
	if (recordFound){
		//
		if ([[DBUtil sharedDBConnection] executeUpdate:@"UPDATE nurse set id=?, npi=?, facility_npi=?, name=?, initials=?, prefix=?, suffix=?, mobile=?,phone=?,fax=?, email=?, credentials = ?, taxonomy_code =?, group_id =? WHERE id =? ",
			 nurseObj.nurseId,
			 nurseObj.nurseNpi,
			 nurseObj.facilityNpi,
			 nurseObj.name,
			 nurseObj.initials,
			 nurseObj.prefix,
			 nurseObj.suffix,
			 nurseObj.mobile,
			 nurseObj.phone,
			 nurseObj.fax,
			 nurseObj.email,
			 nurseObj.credentials,
			 nurseObj.taxonomyCode,
             [NSNumber numberWithInt:nurseObj.groupId],
			 nurseObj.nurseId]==FALSE)
		{
			[[DBUtil sharedDBConnection] rollback];
			success=FALSE;
		}else{
			success=TRUE;
		}
	}else {
		if ([[DBUtil sharedDBConnection] executeUpdate:@"INSERT INTO nurse (id,npi,facility_npi, name, initials, prefix, suffix, mobile, phone, fax, email,credentials,taxonomy_code, group_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
			 nurseObj.nurseId,
			 nurseObj.nurseNpi,
			 nurseObj.facilityNpi,
			 nurseObj.name,
			 nurseObj.initials,
			 nurseObj.prefix,
			 nurseObj.suffix,
			 nurseObj.mobile,
			 nurseObj.phone,
			 nurseObj.fax,
			 nurseObj.email,
			 nurseObj.credentials,
			 nurseObj.taxonomyCode,
             [NSNumber numberWithInt:nurseObj.groupId]]==FALSE)
		{
			[[DBUtil sharedDBConnection] rollback];
			success=FALSE;
		}else
			success=TRUE;
	}
	//success - commit
	[[DBUtil sharedDBConnection] commit];
	
	//success - get the new primary key and return it
	return success;
}
+ (NSMutableDictionary *) getCareTeamForCensus:(NSInteger) censusId
{
	NSMutableDictionary *careTeamDict = [[[NSMutableDictionary alloc] init] autorelease];
	
	NSString *selectDistinctCareTeamMemberTypesQuery = @"SELECT DISTINCT type FROM careteam where census_id=?";
	FMResultSet *careteam_types_rs = [[DBUtil sharedDBConnection]  executeQuery:selectDistinctCareTeamMemberTypesQuery,[NSNumber numberWithInt:censusId]];
	while ([careteam_types_rs next])
	{
		NSString *careteamType = [careteam_types_rs stringForColumn:@"type"];
		NSString *selectCareTeamQuery = @"SELECT "
		 " user_id "
		 " FROM careteam "
		 " WHERE census_id = ? "
		 " AND type = ? ";
		
		FMResultSet *careteam_member_rs = [[DBUtil sharedDBConnection]  executeQuery:selectCareTeamQuery,[NSNumber numberWithInt:censusId],careteamType];
		NSMutableArray *careTeamMembersArray = [[NSMutableArray alloc] init];

		while ([careteam_member_rs next])
		{
			NSString *username = [careteam_member_rs stringForColumn:@"user_id"];
			CareTeamMember_old *careTeamMember = [[CareTeamMember_old alloc] init];

			if([careteamType isEqualToString:@"Nurse"]){
				Nurse *nurseObj = [Nurse getNurseWithUsername:username];
				careTeamMember.memberId = nurseObj.nurseId;
				careTeamMember.memberType = careteamType;
				careTeamMember.prefix = nurseObj.prefix;
				careTeamMember.name = nurseObj.name;
				careTeamMember.suffix = nurseObj.suffix;
				careTeamMember.specialty =  [Helper getSpecialty:nurseObj.taxonomyCode];
				careTeamMember.credentials = nurseObj.credentials;
				careTeamMember.initials = nurseObj.initials;
				careTeamMember.mobile = nurseObj.mobile;
				careTeamMember.phone = nurseObj.phone;
				careTeamMember.fax= nurseObj.fax;
				careTeamMember.email = nurseObj.email;
				careTeamMember.facilityName = nurseObj.facilityName;
			}else if([careteamType rangeOfString:@"Physician"].location != NSNotFound){
				Physician *physicianObj = [Physician getPhysician:username];
				careTeamMember.memberId = [NSString stringWithFormat:@"%.0f",physicianObj.physicianNpi];
				careTeamMember.memberType = careteamType;
				careTeamMember.name = physicianObj.name;
				careTeamMember.specialty = [Helper getSpecialty:physicianObj.specialty];
				careTeamMember.initials = physicianObj.initials;
				careTeamMember.mobile = physicianObj.mobile;
				careTeamMember.phone = physicianObj.phone;
				careTeamMember.fax= physicianObj.fax;
				careTeamMember.email = physicianObj.email;
				careTeamMember.groupName = physicianObj.groupName;
			}
			[careTeamMembersArray addObject:careTeamMember];
			[careTeamMember release];
		}
		[careteam_member_rs close];
		[careTeamDict setObject:careTeamMembersArray forKey:careteamType];
		[careTeamMembersArray release];
	}
	//after looping thru the result set, return the array
	return careTeamDict;
}
+ (Taxonomy *) getTaxonomy:(NSString *) code
{
	NSMutableString *selectTaxonomyQuery = [NSMutableString stringWithString:@""];
	
    [selectTaxonomyQuery appendString:@"SELECT "
	 " code, "
	 " type, "
	 " classification, "
	 " specialization "
	 " FROM taxonomy "
	 " WHERE code = ?"];
	
	FMResultSet *taxonomy_rs = [[DBUtil sharedDBConnection]  executeQuery:selectTaxonomyQuery,code];
	Taxonomy *taxonomyObj = [[[Taxonomy alloc] init] autorelease];
	
	while ([taxonomy_rs next])
	{
		taxonomyObj.code = [taxonomy_rs stringForColumn:@"code"];
		taxonomyObj.type = [taxonomy_rs stringForColumn:@"type"];
		taxonomyObj.classification = [taxonomy_rs stringForColumn:@"classification"];
		taxonomyObj.specialization = [taxonomy_rs stringForColumn:@"specialization"];
	}
	[taxonomy_rs close];
	
	
	//after looping thru the result set, return the array
	return taxonomyObj;
}

+ (NSMutableArray *) getPatientContacts:(NSInteger)patientId
{
	NSMutableArray *patientContactsArray = [[[NSMutableArray alloc] init] autorelease];
	NSMutableString *selectPatientContactsQuery = [NSMutableString stringWithString:@""];
	
    [selectPatientContactsQuery appendString:@"SELECT "
	 " id as patient_contact_id, "
	 " patient_id, "
	 " name, "
	 " relation, "
	 " phone, "
	 " mobile, "
	 " email, "
	 " is_primary "
	 " FROM patient_contact "
	 " WHERE patient_id = ?"];
	
	FMResultSet *patient_contacts_rs = [[DBUtil sharedDBConnection]  executeQuery:selectPatientContactsQuery,[NSNumber numberWithInt:patientId]];
	
	while ([patient_contacts_rs next])
	{
		NSInteger primaryKey = [patient_contacts_rs intForColumn:@"patient_contact_id"];
		PatientContact *patientContactObj = [[PatientContact alloc] initWithPrimaryKey:primaryKey];
		
		patientContactObj.name = [patient_contacts_rs stringForColumn:@"name"];
		patientContactObj.relation = [patient_contacts_rs stringForColumn:@"relation"];
		patientContactObj.phone = [patient_contacts_rs stringForColumn:@"phone"];
		patientContactObj.mobile = [patient_contacts_rs stringForColumn:@"mobile"];
		patientContactObj.email = [patient_contacts_rs stringForColumn:@"email"];
		patientContactObj.isPrimary = [patient_contacts_rs stringForColumn:@"is_primary"];
		
		[patientContactsArray addObject:patientContactObj];
		[patientContactObj release];
	}
	[patient_contacts_rs close];
	//after looping thru the result set, return the array
	return patientContactsArray;

}


@end
