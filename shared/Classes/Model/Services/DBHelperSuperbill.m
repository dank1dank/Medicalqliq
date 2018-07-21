//
//  DBHelperSuperbill.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "DBHelperSuperbill.h"
#import "DBUtil.h"
#import "Helper.h"
#import "DBPersist.h"

@implementation DBHelperSuperbill
#pragma mark -
#pragma mark Superbill

//Superbill queries
+ (NSInteger) getSuperbillId: (double) physicianNpi
{
	//query the physician_superbill to find the facility specific superbill
	NSString *selectSuperbillIdQuery = @"SELECT taxonomy_superbill.superbill_id "
	" FROM physician_superbill,taxonomy_superbill "
	" WHERE physician_superbill.taxonomy_code = taxonomy_superbill.taxonomy_code "
	" AND physician_superbill.physician_npi = ?";
	
	NSInteger superbillId=0;
	
	FMResultSet *superbill_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillIdQuery,[NSNumber numberWithDouble:physicianNpi]];
	
	while ([superbill_rs next])
	{
		superbillId = [superbill_rs intForColumn:@"superbill_id"];
	}
	//if superbill is not assigned, return default superbill
	if(superbillId<=0){
		selectSuperbillIdQuery = @"SELECT superbill.id as superbill_id "
		" FROM superbill "
		" WHERE name = 'Default' ";
	}
	superbill_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillIdQuery,[NSNumber numberWithDouble:physicianNpi]];
	
	while ([superbill_rs next])
	{
		superbillId = [superbill_rs intForColumn:@"superbill_id"];
	}
	[superbill_rs close];
	[selectSuperbillIdQuery release];
	//after looping thru the result set, return the array
	return superbillId;
}

+ (NSMutableArray *) getSuperbillCptGroups:(NSInteger)superbillId
{
	//query cpt groups for the given superbill
	NSString *selectSuperbillCptGroupsQuery = @"SELECT DISTINCT "
	" cpt_group.id as superbill_cpt_group_id, "
	" group_display_order, "
	" name, "
	" data_type, "
	" icd_required, "
	" add_to_charge_desc, "
	" is_annex, "
	" is_required, "
	" two_col_value "
	" FROM superbill_cpt "
	" INNER JOIN cpt_group ON (superbill_cpt.cpt_group_id = cpt_group.id) "
  	" WHERE superbill_cpt.superbill_id = ? "
    " UNION "
	" SELECT DISTINCT "
	" cpt_group.id as superbill_cpt_group_id, "
	" group_display_order, "
	" name, "
	" data_type, "
	" icd_required, "
	" add_to_charge_desc, "
	" is_annex, "
	" is_required, "
	" two_col_value "
	" FROM superbill_annex "
	" INNER JOIN cpt_group ON (superbill_annex.cpt_group_id = cpt_group.id) "
	" WHERE superbill_annex.superbill_id = ? "
	" ORDER BY group_display_order ";
	
	NSMutableArray *superbillCptGroupArray = [[[NSMutableArray alloc] init] autorelease];
	FMResultSet *superbill_cpt_group_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillCptGroupsQuery,[NSNumber numberWithInt:superbillId],[NSNumber numberWithInt:superbillId]];
	
	while ([superbill_cpt_group_rs next])
	{
		NSInteger primaryKey = [superbill_cpt_group_rs intForColumn:@"superbill_cpt_group_id"];
		SuperbillCptGroup *superbillCptGroupObj = [[SuperbillCptGroup alloc] initWithPrimaryKey:primaryKey];
		
		superbillCptGroupObj.superbillCptGroupName = [superbill_cpt_group_rs stringForColumn:@"name"];
		superbillCptGroupObj.superbillCptGroupDataType = [superbill_cpt_group_rs stringForColumn:@"data_type"];
		superbillCptGroupObj.superbillCptGroupIcdRequired = [superbill_cpt_group_rs intForColumn:@"icd_required"];
		superbillCptGroupObj.superbillCptGroupAddToChargeDescription = [superbill_cpt_group_rs intForColumn:@"add_to_charge_desc"];
		superbillCptGroupObj.superbillCptGroupAnnexData = [superbill_cpt_group_rs intForColumn:@"is_annex"];
		superbillCptGroupObj.superbillCptGroupRequired = [superbill_cpt_group_rs intForColumn:@"is_required"];
		superbillCptGroupObj.superbillCptGroupValueSelected = 0;
		superbillCptGroupObj.superbillCptGroupTwoColValue = [superbill_cpt_group_rs intForColumn:@"two_col_value"];
		
		[superbillCptGroupArray addObject:superbillCptGroupObj];
		[superbillCptGroupObj release];
	}
	[superbill_cpt_group_rs close];
	//after looping thru the result set, return the array
	return superbillCptGroupArray;
}


+ (NSMutableArray *) getSuperbillCptCodes:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(double) physicianNpi
{
	
    NSString *selectSuperbillCptCodesQuery = nil;
    FMResultSet *superbill_cpt_codes_rs = nil;
	
	//query cpt codes for the given superbill and cpt group id
	selectSuperbillCptCodesQuery = @"SELECT "
	" superbill_cpt.id as superbill_cpt_id, "
	" cpt.code as code, "
	" superbill_cpt.cpt_abbr, "
	" superbill_cpt.mod_required, "
	" superbill_cpt.cpt_group_id as group_id, "
	" cpt.short_description as cpt_short_description, "
	" cpt.long_description as cpt_long_description, "
	" master_cpt_pft.pft as master_pft, "
	" physician_cpt_pft.pft as physician_pft "
	" FROM superbill_cpt "
	" INNER JOIN cpt ON (superbill_cpt.cpt_code = cpt.code) "
	" LEFT OUTER JOIN master_cpt_pft ON (cpt.code = master_cpt_pft.cpt_code) "
	" LEFT OUTER JOIN physician_cpt_pft ON (cpt.code = physician_cpt_pft.cpt_code) "
	" WHERE superbill_cpt.superbill_id = ? "
	" AND cpt_group_id = ? "
	" ORDER BY code ";
	
	superbill_cpt_codes_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillCptCodesQuery,
							  [NSNumber numberWithInt:superbillId],
							  [NSNumber numberWithInt:superbillCptGroupId]];
	
	
	//    }
	
	NSMutableArray *superbillCptCodesArray = [[[NSMutableArray alloc] init] autorelease];
	
	//add a blank one to show it in the beginning.
    //- that is veeeery strange. we are carrying about UI on db layer...
	/*SuperbillCpt *superbillCptCodeObj = [[SuperbillCpt alloc] initWithPrimaryKey:0];
	[superbillCptCodesArray addObject:superbillCptCodeObj];
	[superbillCptCodeObj release];*/
	
	while ([superbill_cpt_codes_rs next])
	{
		NSInteger primaryKey = [superbill_cpt_codes_rs intForColumn:@"superbill_cpt_id"];
		SuperbillCpt *superbillCptCodeObj = [[SuperbillCpt alloc] initWithPrimaryKey:primaryKey];
		
		superbillCptCodeObj.isAnnexData = NO;
		superbillCptCodeObj.cptCode = [superbill_cpt_codes_rs stringForColumn:@"code"];
		superbillCptCodeObj.cptAbbr = [superbill_cpt_codes_rs stringForColumn:@"cpt_abbr"];
		superbillCptCodeObj.modifierRequired = [superbill_cpt_codes_rs intForColumn:@"mod_required"];
		superbillCptCodeObj.cptGroupId = [superbill_cpt_codes_rs intForColumn:@"group_id"];
		superbillCptCodeObj.cptShortDescription = [superbill_cpt_codes_rs stringForColumn:@"cpt_short_description"];
		superbillCptCodeObj.cptLongDescription = [superbill_cpt_codes_rs stringForColumn:@"cpt_long_description"];
		superbillCptCodeObj.masterCptPft = [superbill_cpt_codes_rs stringForColumn:@"master_pft"];
		superbillCptCodeObj.physicianCptPft = [superbill_cpt_codes_rs stringForColumn:@"physician_pft"];
		[superbillCptCodesArray addObject:superbillCptCodeObj];
		[superbillCptCodeObj release];
	}
	[superbill_cpt_codes_rs close];
	//after looping thru the result set, return the array
	return superbillCptCodesArray;
}
+ (NSMutableArray *) getSuperbillAnnexData:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(NSInteger) valueLocation
{
	
    NSString *selectSuperbillAnnexQuery = nil;
    FMResultSet *superbill_annex_data_rs = nil;
	
	//query cpt codes for the given superbill and cpt group id
	selectSuperbillAnnexQuery = @"SELECT "
	" superbill_annex.id as superbill_annex_id, "
	" value , "
	" value_abbr , "
	" description, "
	" group_display_order, "
	" value_display_order, "
	" superbill_annex.cpt_group_id as group_id "
	" FROM superbill_annex "
	" WHERE superbill_annex.superbill_id = ? "
	" AND superbill_annex.cpt_group_id = ? "
	" AND superbill_annex.value_loc = ? "
	" ORDER BY value_display_order ";
	
	superbill_annex_data_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillAnnexQuery,
							   [NSNumber numberWithInt:superbillId],
							   [NSNumber numberWithInt:superbillCptGroupId],
							   [NSNumber numberWithInt:valueLocation]];
	
	NSMutableArray *superbillAnnexArray = [[[NSMutableArray alloc] init] autorelease];
	
	//add a blank one to show it in the beginning
	/*SuperbillCpt *superbillCptObj = [[SuperbillCpt alloc] initWithPrimaryKey:0];
	[superbillAnnexArray addObject:superbillCptObj];
	[superbillCptObj release];*/
	
	while ([superbill_annex_data_rs next])
	{
		NSInteger primaryKey = [superbill_annex_data_rs intForColumn:@"superbill_annex_id"];
		SuperbillCpt *superbillCptObj = [[SuperbillCpt alloc] initWithPrimaryKey:primaryKey];
		
		superbillCptObj.isAnnexData = YES;
		superbillCptObj.annexValue = [superbill_annex_data_rs stringForColumn:@"value"];
		superbillCptObj.annexValueAbbr = [superbill_annex_data_rs stringForColumn:@"value_abbr"];
		superbillCptObj.annexDescription = [superbill_annex_data_rs stringForColumn:@"description"];
		superbillCptObj.cptGroupId = [superbill_annex_data_rs intForColumn:@"group_id"];
		
		[superbillAnnexArray addObject:superbillCptObj];
		[superbillCptObj release];
	}
	[superbill_annex_data_rs close];
	//after looping thru the result set, return the array
	return superbillAnnexArray;
}

+ (NSMutableArray *) getAllCptModifiers
{
	//query all modifiers
	NSString *selectModifiersQuery = @"SELECT "
	" modifier, "
	" description "
	" FROM modifier "
	" ORDER BY modifier" ;
    
	NSMutableArray *modifiersArray = [[[NSMutableArray alloc] init] autorelease];
	FMResultSet *modifiers_rs = [[DBUtil sharedDBConnection] executeQuery:selectModifiersQuery];
	
	// add a blank one in the begenning
	SuperbillCptModifier *modifierObj = [[SuperbillCptModifier alloc] initWithPrimaryKey:0];
	[modifiersArray addObject:selectModifiersQuery];
	[modifierObj release];
    
	while ([modifiers_rs next])
	{
		SuperbillCptModifier *modifierObj = [[SuperbillCptModifier alloc] initWithPrimaryKey:0];
		
		modifierObj.modifier = [modifiers_rs stringForColumn:@"modifier"];
		modifierObj.modifierDescription = [modifiers_rs stringForColumn:@"description"];
		[modifiersArray addObject:modifierObj];
		[modifierObj release];
	}
	[modifiers_rs close];
	//after looping thru the result set, return the array
	return modifiersArray;
}


+ (NSMutableArray *) getSuperbillCptModifiers:(NSInteger)superbillId
{
	//query cpt modifiers for the given superbill cpt id
	NSString *selectSuperbillCptModifiersQuery = @"SELECT DISTINCT "
	" superbill_cpt_modifier.id as superbill_cpt_modifier_id, "
	" superbill_cpt_modifier.modifier, "
	" modifier.description "
	" FROM superbill_cpt_modifier "
	" INNER JOIN superbill ON (superbill_cpt_modifier.superbill_id = superbill.id) "
	" LEFT OUTER JOIN modifier ON (superbill_cpt_modifier.modifier = modifier.id) "
	" WHERE superbill_cpt_modifier.superbill_id = ? "
	" ORDER BY display_order" ;
    
    //TTDLog(@"query superbill %d", superbillId);
	
	NSMutableArray *superbillCptModifiersArray = [[[NSMutableArray alloc] init] autorelease];
	FMResultSet *superbill_cpt_modifiers_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillCptModifiersQuery,[NSNumber numberWithInt:superbillId]];
	
	// add a blank one in the begenning
    // - we don't have to worry about UI layer on db layer
	/*SuperbillCptModifier *superbillCptModifierObj = [[SuperbillCptModifier alloc] initWithPrimaryKey:0];
	[superbillCptModifiersArray addObject:superbillCptModifierObj];
    [superbillCptModifierObj release];*/
	
	while ([superbill_cpt_modifiers_rs next])
	{
		NSInteger primaryKey = [superbill_cpt_modifiers_rs intForColumn:@"superbill_cpt_modifier_id"];
		SuperbillCptModifier *superbillCptModifierObj = [[SuperbillCptModifier alloc] initWithPrimaryKey:primaryKey];
		
		superbillCptModifierObj.superbillId = superbillId;
		superbillCptModifierObj.modifier = [superbill_cpt_modifiers_rs stringForColumn:@"modifier"];
		superbillCptModifierObj.modifierDescription = [superbill_cpt_modifiers_rs stringForColumn:@"description"];
		[superbillCptModifiersArray addObject:superbillCptModifierObj];
		[superbillCptModifierObj release];
	}
	[superbill_cpt_modifiers_rs close];
	//after looping thru the result set, return the array
	return superbillCptModifiersArray;
}

+ (NSMutableArray *) getSuperbillsToDisplay
{
	
	//query all superbills for the picker list
	NSString *selectSuperbillQuery = @"SELECT "
	" id as superbill_id, "
	" name as superbill_name "
	" FROM superbill ";
	
	NSMutableArray *superbillArray = [[[NSMutableArray alloc] init] autorelease];
	FMResultSet *superbill_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillQuery];
	
	while ([superbill_rs next])
	{
		NSInteger primaryKey = [superbill_rs intForColumn:@"superbill_id"];
		Superbill *superbillObj = [[Superbill alloc] initWithPrimaryKey:primaryKey];
		
		superbillObj.name = [superbill_rs stringForColumn:@"superbill_name"];
		[superbillArray addObject:superbillObj];
		[superbillObj release];
	}
	[superbill_rs close];
	//after looping thru the result set, return the array
	return superbillArray;
	
}

+ (NSInteger) addSuperbill:(Superbill *) superbill
{
	NSInteger superbillId = 0;
	//SUPERBILL UPDATE/INSERT
	NSString *selectSuperbillQuery = @"SELECT "
	" id as superbill_id"
	" FROM superbill "
	" WHERE UPPER(name) = ?";
	FMResultSet *superbill_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillQuery,[superbill.name uppercaseString]];
	BOOL recordFound=FALSE;
	while ([superbill_rs next]) {
		recordFound = TRUE;
		superbillId = [superbill_rs intForColumn:@"superbill_id"];
	}
	
	//if recordFound there is nothing to update, just ignore otherwise insert
	if (!recordFound){
		//begin transation to lock the table while inserting
		[[DBUtil sharedDBConnection] beginTransaction];
		if ([[DBUtil sharedDBConnection] executeUpdate:@"INSERT INTO superbill (name,last_updated_user,last_updated) VALUES (?,?,?)",
			 superbill.name,
			 [Helper getUsername],
			 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]]==FALSE)
		{
			[[DBUtil sharedDBConnection] rollback];
			//error - return 0;
			return 0;
		}
		superbillId = [[DBUtil sharedDBConnection] lastInsertRowId];
		//success - commit
		[[DBUtil sharedDBConnection] commit];
	}
	
	//success - get the new primary key and return it
	return superbillId;
}

+ (NSInteger) addSuperbillCpt:(SuperbillCpt *) superbillCpt
{
	NSInteger superbillCptId = 0;
	BOOL recordFound=FALSE;
	Cpt *thisCptObj = [Cpt getCptObjectForCptCode:superbillCpt.cptCode];
	
	if(thisCptObj.code!=nil){
		//SUPERBILL CPT UPDATE/INSERT
		NSString *selectSuperbillCptQuery = @"SELECT "
		" id as superbill_cpt_id"
		" FROM superbill_cpt "
		" WHERE superbill_id = ?"
		" AND cpt_code =? ";
		FMResultSet *superbill_cpt_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillCptQuery,[NSNumber numberWithInt:superbillCpt.superbillId],thisCptObj.code];
		while ([superbill_cpt_rs next]) {
			recordFound = TRUE;
			superbillCptId = [superbill_cpt_rs intForColumn:@"superbill_cpt_id"];
		}
	}
	
	//if recordFound there is nothing to update, just ignore otherwise insert
	if (!recordFound){
		//begin transation to lock the table while inserting
		[[DBUtil sharedDBConnection] beginTransaction];
		
		if ([[DBUtil sharedDBConnection] executeUpdate:@"INSERT INTO superbill_cpt (superbill_id,cpt_group_id, cpt_code,last_updated_user,last_updated) VALUES (?,?,?,?,?,?)",
			 [NSNumber numberWithInt:superbillCpt.superbillId],
			 [NSNumber numberWithInt:superbillCpt.cptGroupId],
			 thisCptObj.code,		 
			 [Helper getUsername],
			 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]]==FALSE)
		{
			[[DBUtil sharedDBConnection] rollback];
			//error - return 0;
			return 0;
		}
		superbillCptId = [[DBUtil sharedDBConnection] lastInsertRowId];
		//success - commit
		[[DBUtil sharedDBConnection] commit];
	}
	
	//success - get the new primary key and return it
	return superbillCptId;
}

+ (NSInteger) addSuperbillIcd:(SuperbillIcd *)superbillIcd
{
	NSInteger superbillIcdId = 0;
	
	//SUPERBILL ICD UPDATE/INSERT
	NSString *selectSuperbillCptQuery = @"SELECT "
	" id as superbill_icd_id"
	" FROM superbill_icd "
	" WHERE superbill_cpt_id = ?"
	" AND icd_code =? ";
	FMResultSet *superbill_icd_rs = [[DBUtil sharedDBConnection] executeQuery:selectSuperbillCptQuery,[NSNumber numberWithInt:superbillIcd.superbillCptId],superbillIcd.icdCode];
	BOOL recordFound=FALSE;
	while ([superbill_icd_rs next]) {
		recordFound = TRUE;
		superbillIcdId = [superbill_icd_rs intForColumn:@"superbill_icd_id"];
	}
	//if recordFound there is nothing to update, just ignore otherwise insert
	if (!recordFound){
		//begin transation to lock the table while inserting
		[[DBUtil sharedDBConnection] beginTransaction];
		
		if ([[DBUtil sharedDBConnection] executeUpdate:@"INSERT INTO superbill_icd (superbill_cpt_id, icd_code,last_updated_user,last_updated) VALUES (?,?,?,?)",
			 [NSNumber numberWithInt:superbillIcd.superbillCptId],
			 superbillIcd.icdCode,
			 [Helper getUsername],
			 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]]==FALSE)
		{
			[[DBUtil sharedDBConnection] rollback];
			//error - return 0;
			return 0;
		}
		//success - get the new primary key and return it
		superbillIcdId = [[DBUtil sharedDBConnection] lastInsertRowId];
		//success - commit
		[[DBUtil sharedDBConnection] commit];
	}
	return superbillIcdId;
}

+ (NSInteger) addSuperbillCptModifier:(SuperbillCptModifier *) superbillCptModifier
{
	NSInteger superbillCptModifierId = 0;
	//success - get the new primary key and return it
	return superbillCptModifierId;
}

+ (NSInteger) getSuperbillForSpecialty:(NSString *) specialty
{
	//get the superbill for the given taxonomy_code
	NSString *selectTaxonomyQuery = @"SELECT superbill_id "
	" FROM taxonomy_superbill "
	" WHERE taxonomy_code = ? ";
	
	FMResultSet *taxonomy_superbill_rs = [[DBUtil sharedDBConnection] executeQuery:selectTaxonomyQuery,specialty];
	
	NSInteger superbillId = 0;
	
	BOOL recordFound=FALSE;
	while ([taxonomy_superbill_rs next])
	{
		superbillId = [taxonomy_superbill_rs intForColumn:@"superbill_id"];
		recordFound = TRUE;
	}
	if(!recordFound){
		selectTaxonomyQuery = @"SELECT superbill_id "
		" FROM taxonomy_superbill "
		" WHERE taxonomy_code = ? ";
		NSString *generalSpecialty = [NSString stringWithFormat:@"%@%@",[specialty substringWithRange:NSMakeRange(0, 4)],@"00000X"];
		FMResultSet *taxonomy_superbill_rs = [[DBUtil sharedDBConnection] executeQuery:selectTaxonomyQuery,generalSpecialty];
		
		while ([taxonomy_superbill_rs next])
		{
			superbillId = [taxonomy_superbill_rs intForColumn:@"superbill_id"];
			recordFound = TRUE;
		}
	}
	if(!recordFound){
		selectTaxonomyQuery = @"SELECT superbill.id as superbill_id "
		" FROM superbill "
		" WHERE name = 'Default' ";
		
		
		taxonomy_superbill_rs = [[DBUtil sharedDBConnection] executeQuery:selectTaxonomyQuery];
		
		while ([taxonomy_superbill_rs next])
		{
			superbillId = [taxonomy_superbill_rs intForColumn:@"superbill_id"];
		}
	}
	
	[taxonomy_superbill_rs close];
	[selectTaxonomyQuery release];
	//after looping thru the result set, return the array
	return superbillId;
}

+ (SuperbillCptGroup*) getCptGroup:(NSInteger) cptGroupId
{
	NSString *cptGroupQuery = @"SELECT * "
	" FROM cpt_group "
	" WHERE id = ? ";

	FMResultSet *cpt_group_rs = [[DBUtil sharedDBConnection] executeQuery:cptGroupQuery,[NSNumber numberWithInt:cptGroupId]];
	SuperbillCptGroup *superbillCptGroupObj = [[SuperbillCptGroup alloc] initWithPrimaryKey:0];
	
	while ([cpt_group_rs next])
	{
		NSInteger primaryKey = [cpt_group_rs intForColumn:@"id"];
		superbillCptGroupObj.superbillCptGroupId = primaryKey;
		superbillCptGroupObj.superbillCptGroupName = [cpt_group_rs stringForColumn:@"name"];
		superbillCptGroupObj.superbillCptGroupDataType = [cpt_group_rs stringForColumn:@"data_type"];
		superbillCptGroupObj.superbillCptGroupIcdRequired = [cpt_group_rs intForColumn:@"icd_required"];
		superbillCptGroupObj.superbillCptGroupAddToChargeDescription = [cpt_group_rs intForColumn:@"add_to_charge_desc"];
		superbillCptGroupObj.superbillCptGroupAnnexData = [cpt_group_rs intForColumn:@"is_annex"];
		superbillCptGroupObj.superbillCptGroupRequired = [cpt_group_rs intForColumn:@"is_required"];
		superbillCptGroupObj.superbillCptGroupTwoColValue = [cpt_group_rs intForColumn:@"two_col_value"];
	}
	[cpt_group_rs close];
	//after looping thru the result set, return the array
	return superbillCptGroupObj;
	
}


+ (BOOL) updatePhysicianCptPft:(NSString *)cptCode:(NSString *)cptPft
{
    return NO;
}

+ (NSString *) getTaxonomyCodeForSpeciality:(NSString*)specialty
{
    return nil;
}


@end
