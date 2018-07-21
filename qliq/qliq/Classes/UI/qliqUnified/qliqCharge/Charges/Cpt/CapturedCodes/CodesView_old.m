//
//  Home.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "CodesView_old.h"
#import "Census_old.h"
#import "Facility_old.h"
#import "Encounter_old.h"
#import "EncounterNote.h"
#import "EncounterCpt.h"
#import "EncounterIcd.h"
#import "Icd.h"
#import "Cpt.h"
#import "Patient_old.h"
#import "Physician.h"
#import "Appointment.h"
#import "AddCptViewController.h"
#import "ObjectListViewController.h"
#import "ObjectSelectViewController.h"
#import "PatientHeaderView.h"
#import "LightGreyGlassGradientView.h"
#import "StretchableButton.h"
#import "ICDTableViewCell.h"
#import "CPTTableViewCell.h"
#import "AddTableViewCell.h"
#import "IcdDetailsView.h"
#import "Patient_old.h"
#import "CodesByDateViewController.h"
#import "Buddy.h"
#import "RoundViewController.h"
#import "EncounterNotesViewController.h"
#import "NSDate+Helper.h"
#import "Helper.h"
#import "AllChargesTableViewCell.h"
#import "ConversationListViewController.h"
#import "Outbound.h"
#import "DBHelperConversation.h"

#define kPastDaysNumber     30
#define kFutureDaysNumber   7
#define SectionHeaderHeight 40

@interface CodesView_old () <UITableViewDelegate, UITableViewDataSource, PatientHeaderViewDelegate>

@property (nonatomic, retain) UIView *tableHeader;
- (void)updateTableWithOptions:(NSDictionary *)options;
- (void)expandAllSections;
- (void)collapseAllSections;
- (void)setFinishButtonState;

@end

@implementation CodesView_old
//@synthesize censusId,apptId,physicianNpi,dateOfService = _dateOfService, patientName;
@synthesize censusObj = _censusObj, apptObj = _apptObj;
@synthesize tableView = _tableView;
@synthesize tableHeader = _tableHeader;

- (void)refreshCodesData {
	//NSTimeInterval self.censusObj.selectedDos = dosInterval==0?dosInterval:self.censusObj.dateOfService;
	NSLog(@"census = %d, %f, %@, %f", self.censusObj.censusId, self.censusObj.dateOfService,_selectedDos, self.censusObj.selectedDos);
	
	encounterId = [Encounter_old getEncounterForCensus:self.censusObj.censusId :self.censusObj.physicianNpi :self.censusObj.selectedDos];
	
	[arrayToDisplay removeAllObjects];
	arrayToDisplay = [[EncounterCpt getChargesToDisplayForCensus:self.censusObj andDos:self.censusObj.selectedDos] retain];
    
	
    
	if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")] )
	{
		//_editButton.enabled=NO;
		_notesButton.enabled=NO;
		_copyButton.enabled=NO;
		_finishButton.enabled=NO;
		self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Charges", @"Charges") 
															  buttonImage:nil 
															 buttonAction:nil];
	}else {
		self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Charges", @"Charges") 
															  buttonImage:[UIImage imageNamed:@"btn-add"] 
															 buttonAction:@selector(addNewCpt:)];
		
		[self setFinishButtonState];
		_copyButton.enabled = ([arrayToDisplay count] == 0);
		_notesButton.enabled = ([arrayToDisplay count] > 0); 
	}
	[self.tableView reloadData];
	
}
- (void)resetPrimaryForIcds:(NSArray *)icdList {
    for (EncounterIcd *icdObj in icdList) {
        [EncounterIcd resetPrimary:icdObj];
        icdObj.isPrimary = NO;
    }
    if ([icdList count] > 0){
        EncounterIcd *primaryIcd = [icdList objectAtIndex:0];
        primaryIcd.isPrimary = YES;
        [EncounterIcd setPrimary:primaryIcd];
    }
}
#pragma mark -
#pragma mark Toolbar actions

- (void)markEncounterComplete:(id)sender {
//    [_censusObj setMetadataAuthor:[Metadata defaultAuthor]];
    [Encounter_old updateEncounter:encounterId withStatus:EncounterStatusComplete];
    [_censusObj setRevisionDirty:YES];    
	[self refreshCodesData];
    //[self.navigationController popViewControllerAnimated:YES];
}

- (void)markEncounterWIP {
//    [_censusObj setMetadataAuthor:[Metadata defaultAuthor]];
    [Encounter_old updateEncounter:encounterId withStatus:EncounterStatusWIP];
    [_censusObj setRevisionDirty:YES];    
}

- (void)markEncounterDeleted {
//    [_censusObj setMetadataAuthor:[Metadata defaultAuthor]];    
    [Encounter_old updateEncounter:encounterId withStatus:EncounterStatusDeleted];
    [_censusObj setRevisionDirty:YES];    
}

- (void)showPatientInfo:(id)sender {
    
}

- (void)setCellTextDisabled:(UITableViewCell *)cell {
	((AllChargesTableViewCell *)cell).lblCptCodes.textColor =[UIColor colorWithWhite: 0.6677 alpha: 1.0];
	((AllChargesTableViewCell *)cell).lblIcdCodes.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0];
	((AllChargesTableViewCell *)cell).lblDate.textColor = [UIColor colorWithWhite: 0.6677 alpha: 1.0];
}

- (void)setCellTextNormal:(UITableViewCell *)cell {
	((AllChargesTableViewCell *)cell).lblCptCodes.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];
	((AllChargesTableViewCell *)cell).lblIcdCodes.textColor = [UIColor colorWithRed:0.4275 green:0.4314 blue:0.4431 alpha:1.0f];
	((AllChargesTableViewCell *)cell).lblDate.textColor = [UIColor colorWithRed:0.73 green:0.21 blue:0.15 alpha:1.0f];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")] || self.censusObj.dateOfService==0)
		return 1;
	else   
		return [arrayToDisplay count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int rowCount=0;
	if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")] || self.censusObj.dateOfService==0)
		rowCount = [arrayToDisplay count];
	else {
		//get the cpt dictionary object from array at the section index
		NSDictionary  *sectionObj = [arrayToDisplay objectAtIndex:section];
		//get the corresponding icd codes with the key "icds"
		NSArray *rowArray = [sectionObj objectForKey:@"icds"];
		//if there are icds, return the number of icds plus one to display the cpt in first row;
		// second row to add new icd
		rowCount = 1;
		if (section == _openedSection || _showAllSections) {
			EncounterCpt *encounterCptObj = [sectionObj objectForKey:@"cpt"];
			if([encounterCptObj.cptCode isEqualToString:NSLocalizedString(@"NOVISIT", @"NOVISIT")])
				rowCount = [rowArray count] + 1;
			else
				rowCount = [rowArray count] + 2;
		}
		
	}
    NSLog(@"rows (%d) = %d", section, rowCount);
    return rowCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier =[NSString stringWithFormat:@"%d,%d",indexPath.section,indexPath.row];
	UITableViewCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"MM/dd"];
	
	if(tableView.tag==0){
		if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")]|| self.censusObj.dateOfService==0){
			if (cell == nil)
				cell = [[[AllChargesTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
			AllCharges *allChargesObj = [arrayToDisplay objectAtIndex:indexPath.row];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			((AllChargesTableViewCell *)cell).lblCptCodes.text = allChargesObj.strCptCodes;
			((AllChargesTableViewCell *)cell).lblIcdCodes.text = allChargesObj.strIcdCodes;
			((AllChargesTableViewCell *)cell).showStatusImage = YES;
			((AllChargesTableViewCell *)cell).lblDate.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:allChargesObj.dateOfService]];
			switch (allChargesObj.encounterStatus) {
				case EncounterStatusWIP:
				{
					[self setCellTextNormal:cell];
					((AllChargesTableViewCell *)cell).statusImage.image = [UIImage imageNamed:@"status-wip"];
				}
					break;
				case EncounterStatusNoVisit:
				{
					[self setCellTextDisabled:cell];
					((AllChargesTableViewCell *)cell).statusImage.image = [UIImage imageNamed:@"status-novisit"];
				}
					break;
					
				case EncounterStatusComplete:
				{
					[self setCellTextNormal:cell];
					((AllChargesTableViewCell *)cell).statusImage.image = [UIImage imageNamed:@"status-done"];
				}
					break;
				case EncounterStatusVisit:
				default:
					[self setCellTextNormal:cell];
					((AllChargesTableViewCell *)cell).statusImage.image = nil;
					break;
			}
		}else {
			NSDictionary *dictObj = [arrayToDisplay objectAtIndex:indexPath.section];
			if (cell == nil) {
				if(indexPath.row==0){
					cell = [[[CPTTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
				}
				else if ([[dictObj objectForKey:@"icds"] count] > 0 && indexPath.row <= [[dictObj objectForKey:@"icds"] count]) {
					cell = [[[ICDTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
				}
				else {
					cell = [[[AddTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
				}
			}
			
			//Get the cpt object with the key "cpt"
			EncounterCpt *sectionObj = [dictObj objectForKey:@"cpt"];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			if(indexPath.row==0){
				UIButton *accessoryButton = [self cptCellChevronWithTag:indexPath.row width:32 height:32];
				[accessoryButton addTarget:self action:@selector(presentIcdDetails:) forControlEvents:UIControlEventTouchUpInside];
				cell.accessoryView = accessoryButton;
				if (_openedSection == indexPath.section) {
					((CPTTableViewCell *)cell).opened = YES;
				}
				else {
					((CPTTableViewCell *)cell).opened = NO;
				}
				NSMutableString *cptDesc = [NSMutableString stringWithString:@""];
				[cptDesc appendString:sectionObj.codeWithModifiers];
				[cptDesc appendString:@" • "];
				Cpt *thisCpt = [Cpt getCptObjectForCptCode:sectionObj.cptCode];
				NSString *shortDesc = [Cpt getShortDescription:thisCpt];
				[cptDesc appendString:shortDesc];
				
				cell.textLabel.text = cptDesc;
			}
			else if (indexPath.row <= [[dictObj objectForKey:@"icds"] count]) {
				((ICDTableViewCell *)cell).visibledIndicators = NO;
				UIButton *accessoryButton = [self icdCellChevronWithTag:indexPath.row width:32 height:48];
				[accessoryButton addTarget:self action:@selector(presentIcdDetails:) forControlEvents:UIControlEventTouchUpInside];
				cell.accessoryView = accessoryButton;
				
				NSMutableArray *rowArray = [dictObj objectForKey:@"icds"];
				NSString *icdCode;
				NSMutableString *icdDesc = [NSMutableString stringWithString:@""];
				
				//get the icd objects from the dictionary with the key "icds"
				if([rowArray count]>0){
					//get the ICD object from the array
					//Array index starts at 0 but we start painting icd records from index 1
					//so we need to subtract 1 from the indexpath.row to find the right array element.
					EncounterIcd *rowObj = [rowArray objectAtIndex:indexPath.row-1];
					((ICDTableViewCell *)cell).primaryIcd = rowObj.isPrimary;
					icdCode = rowObj.icdCode;
					Icd *thisIcd = [Icd getIcdObjectForIcdcode:icdCode];
					[icdDesc appendString:[Icd getShortDescription:thisIcd]];
					
				}else{
					icdCode=@"";
					[icdDesc setString:@""];
				}
				
				cell.textLabel.text=[icdDesc capitalizedString];
				cell.detailTextLabel.text=icdCode;
				cell.showsReorderControl=YES;
				//            cell.indentationLevel=1;
				
				cell.accessoryType=0;
				cell.editingAccessoryType=0;
				cell.selectionStyle=0;
			}
			else
            {
				cell.textLabel.text = @"Add ICD Code";
			}
		}
        return cell;
    }
    return cell;
}

// Override to support editing the list
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//Get the cpt dictionary object from the array at the section index
	NSDictionary *dictObj = [arrayToDisplay objectAtIndex:indexPath.section];
	//Get the cpt object with the key "cpt"
	EncounterCpt *sectionObj = [dictObj objectForKey:@"cpt"];
	encounterId = sectionObj.encounterId;
	
	//get the icd objects from the dictionary with the key "icds"
	NSMutableArray *rowArray = [dictObj objectForKey:@"icds"];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BOOL success = NO;
        // Delete the row from the data source
		if(indexPath.row==0){ // this is cpt
			if([EncounterCpt deleteEncounterCpt:sectionObj.encounterCptId]) {
				NSLog(@"successfully deleted the cpt and associated modifiers and icd records");
                //[_censusObj setMetadataAuthor:[Metadata defaultAuthor]];
                [_censusObj setRevisionDirty:YES];
                success = YES;
				//if this is the last cpt, then delete the associated encounter also
				
            }
 		}else { // icd
			if([rowArray count]>0){
				EncounterIcd *rowObj = [rowArray objectAtIndex:indexPath.row-1];
				if ([EncounterIcd deleteEncounterIcd:rowObj]) {
					NSLog(@"successfully deleted the icd record");
                    //[_censusObj setMetadataAuthor:[Metadata defaultAuthor]];
                    [_censusObj setRevisionDirty:YES];
                    success = YES;
					[rowArray removeObjectAtIndex:indexPath.row-1];
					[self resetPrimaryForIcds:rowArray];
                }
			}
		}
        if (success) {
            [arrayToDisplay removeAllObjects];
            arrayToDisplay = [[EncounterCpt getChargesToDisplayForCensus:self.censusObj andDos:self.censusObj.selectedDos] retain];
			//self.censusObj.selectedDos = [Helper conevrtDosToTimeInterval:_selectedDos];
			//[self refreshCodesData];
			// if the returned array size is zero means all the cpts are deleted
			// we need to delete the associated encounter also
			if([arrayToDisplay count]==0){
				[self markEncounterDeleted];
				self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Charges", @"Charges") 
																	  buttonImage:[UIImage imageNamed:@"btn-add"] 
																	 buttonAction:@selector(addNewCpt:)];
			}else
			{
				[self markEncounterWIP];		
				if([arrayToDisplay count]==1){
					//means only one cpt, expand it
					_openedSection=0;
				}
			}
			//[tableView reloadData];
			[horizontalPicker reload];
			[horizontalPicker selectRow:lastSelectedPickerRow animated:NO];
			[horizontalPicker forceMagnifierReresh];
			_copyButton.enabled = ([arrayToDisplay count] == 0);
            [self setFinishButtonState];
        }
		
		
    }   
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")] || self.censusObj.dateOfService==0)
	{
		return NO;
	}else {
		
		if (indexPath.section < [arrayToDisplay count]) {
			NSDictionary *dictObj = [arrayToDisplay objectAtIndex:indexPath.section];
			if (indexPath.row > [[dictObj objectForKey:@"icds"] count]) {
				return NO;
			}
		}
		return YES;
	}
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *dictObj = [arrayToDisplay objectAtIndex:indexPath.section];
    if (indexPath.row > [[dictObj objectForKey:@"icds"] count]) {
        return NO;
    }
    else if(indexPath.row > 0) {
        return YES;
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath{
    if((fromIndexPath.section == toIndexPath.section) && (fromIndexPath.row != toIndexPath.row)){
        if(toIndexPath.row>0){
            //remove and add the icd at appropriate index in the datamodel
            //Get the cpt dictionary object from the array at the section index
            NSDictionary *dictObj = [arrayToDisplay objectAtIndex:fromIndexPath.section];
            NSMutableArray *rowArray = [dictObj objectForKey:@"icds"];
            //get the from index of the icd
            //we are subtracting 1 to the index becasue index zero is cpt
            EncounterIcd *fromIcdObj = [[rowArray objectAtIndex:fromIndexPath.row-1] retain];
            EncounterIcd *toIcdObj = [[rowArray objectAtIndex:toIndexPath.row-1] retain];
			
            [rowArray removeObjectAtIndex:fromIndexPath.row-1];
			[rowArray removeObjectAtIndex:toIndexPath.row-1];
			
            [rowArray insertObject:fromIcdObj atIndex:toIndexPath.row-1];
			[rowArray insertObject:toIcdObj atIndex:fromIndexPath.row-1];
			
            [fromIcdObj release];
			[toIcdObj release];
            [self resetPrimaryForIcds:rowArray];
            [self.tableView reloadData];
			[self markEncounterWIP];
        }else {
            [self.tableView reloadData];
        }
    }else{
        [self.tableView reloadData];
    }
}
#pragma mark -
#pragma mark HorizontalPickerViewDelegate

- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                        dateForRow: (NSInteger) row
{
    return [pickerViewArray objectAtIndex: row];
}


- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                         dayForRow: (NSInteger) row
{
    NSString* result=nil;
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"MM/dd/yy"];
	NSString *thisDos = [pickerViewArray objectAtIndex:row];
	NSTimeInterval thisTimeIntervalDos = [Helper conevrtDosToTimeInterval:thisDos];
	
    NSDate *date = [dateFormatter dateFromString:thisDos];
    
    if (date != nil) 
    {
		[cptInsidePickerViewArray removeAllObjects];
		cptInsidePickerViewArray = [[EncounterCpt getChargesToDisplayForCensus:self.censusObj andDos:thisTimeIntervalDos] retain];
		
		if ([cptInsidePickerViewArray count] > 0) 
		{
			NSDictionary *dictObj = [cptInsidePickerViewArray objectAtIndex:0];
			EncounterCpt *encounterCptObj = [dictObj objectForKey:@"cpt"];
			NSMutableString *str = [NSMutableString stringWithString:@""];
			[str appendString:encounterCptObj.cptCode];
			if([cptInsidePickerViewArray count]>1){
				[str appendString:@"+"];
			}
			[str appendString:@" ("];
			[str appendString:self.censusObj.physicianInitials];
			[str appendString:@")"];
			
			result = NSLocalizedString(str, str);;
		}
		else 
		{
			Encounter_old *encounterObj = [Encounter_old getEncounterObjForCensus:self.censusObj.censusId :self.censusObj.physicianNpi :thisTimeIntervalDos];
			if(encounterObj!=nil && encounterObj.encounterId==0){
				if(self.censusObj.censusType == Consult)
					result = NSLocalizedString(@"( No Visit )", @"( No Visit )");
				else 
					result = NSLocalizedString(@" ", @" ");
			}else if(encounterObj!=nil && encounterObj.encounterId>0 && encounterObj.status == EncounterStatusNoVisit){
				result = NSLocalizedString(@"( No Visit )", @"( No Visit )");
			}else if(encounterObj!=nil && encounterObj.encounterId>0 && encounterObj.status == EncounterStatusVisit){
				result = NSLocalizedString(@" ", @" ");
			}else {
				result = NSLocalizedString(@" ", @" ");
			}
			
		}
	}
    //}
    else 
    {
		NSString *daysStr = [NSString stringWithFormat:@"%d DAYS",days+1];
        result = NSLocalizedString(daysStr, daysStr);
    }
    return result;
}


- (NSInteger) horizontalPickerViewNumberOfRows: (HorizontalPickerView*) pickerView
{
    return [pickerViewArray count];
}

- (void) horizontalPickerView: (HorizontalPickerView*) pickerView
                 didSelectRow: (NSInteger) row
{
	lastSelectedPickerRow = row;
    _selectedDos = [pickerViewArray objectAtIndex:row];
	//self.censusObj.selectedDos = [Helper conevrtDosToTimeInterval:_selectedDos];
	self.censusObj.selectedDos = [Helper conevrtDosToTimeInterval:_selectedDos]; 
	/*
	if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")]){
	}else{
		self.censusObj.dateOfService = [Helper conevrtDosToTimeInterval:_selectedDos];
	}*/
	[self refreshCodesData];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	//    NSDictionary *dictObj = [arrayToDisplay objectAtIndex:indexPath.section];
    if (indexPath.row == 0) {
        return HEADER_HEIGHT;
    }
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")]|| self.censusObj.dateOfService==0)
	{
	}else {
		// Navigation logic -- create and push a new view controller
		NSDictionary *dictObj = [arrayToDisplay objectAtIndex:indexPath.section];
		EncounterCpt *encounterCptObj = [dictObj objectForKey:@"cpt"];
		if(![encounterCptObj.cptCode isEqualToString:NSLocalizedString(@"NOVISIT", @"NOVISIT")])
		{	
			if (indexPath.row == 0) {
				// show / hide section
				NSArray *rowArray = [dictObj objectForKey:@"icds"];
				int countOfRowsToInsert = 0;
				int countOfRowsToDelete = 0;
				NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
				if (indexPath.section != _openedSection) {
					countOfRowsToInsert = [rowArray count] + 1;
					if (_openedSection > -1) {
						countOfRowsToDelete = [[[arrayToDisplay objectAtIndex:_openedSection] objectForKey:@"icds"] count] + 1;
					}
					for (NSInteger i = 0; i < countOfRowsToInsert; i++) {
						[indexPathsToInsert addObject:[NSIndexPath indexPathForRow:(i+1) inSection:indexPath.section]];
					}
				}
				else {
					countOfRowsToDelete = [rowArray count] + 1;
				}
				
				/*
				 Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
				 */
				NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
				for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
					[indexPathsToDelete addObject:[NSIndexPath indexPathForRow:(i+1) inSection:_openedSection]];
				}
				
				// Style the animation so that there's a smooth flow in either direction.
				UITableViewRowAnimation insertAnimation;
				UITableViewRowAnimation deleteAnimation;
				if (_openedSection < indexPath.section) {
					insertAnimation = UITableViewRowAnimationTop;
					deleteAnimation = UITableViewRowAnimationBottom;
				}
				else {
					insertAnimation = UITableViewRowAnimationTop;
					deleteAnimation = UITableViewRowAnimationTop;
				}
				
				UITableViewCell *cellClosed = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:_openedSection]];
				((CPTTableViewCell *)cellClosed).opened = NO;
				if (_openedSection == -1 || _openedSection != indexPath.section) {
					_openedSection = indexPath.section;
					UITableViewCell *cellOpened = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:_openedSection]];
					((CPTTableViewCell *)cellOpened).opened = YES;
				}
				else {
					_openedSection = -1;
				}
				
				NSDictionary *updateDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
												  indexPathsToDelete, @"pathsToDelete",
												  indexPathsToInsert, @"pathsToInsert",
												  [NSNumber numberWithInteger:insertAnimation], @"insertAnimation",
												  [NSNumber numberWithInteger:deleteAnimation], @"deleteAnimation",
												  nil];
				// Apply the updates.
				[self updateTableWithOptions:updateDictionary];
				[indexPathsToInsert release];
				[indexPathsToDelete release];
				//        [_tableView reloadData];
			}
			else if (indexPath.row > [[dictObj objectForKey:@"icds"] count]) {
				//Get the cpt object with the key "cpt"
				EncounterCpt *sectionObj = [dictObj objectForKey:@"cpt"];
				//Get the Icd count to figure out if its primary.
				NSMutableArray *icdArray = [dictObj objectForKey:@"icds"];
				//If the count is zero, then its first one, set primary to TRUE
				//otherwise set FALSE
				[icdArray retain];
				BOOL isPrimary = YES;
				if([icdArray count] > 0)
					isPrimary = NO;
				[icdArray release];
				
				// MZ: selecting ICD styling + massive refactoring
				ObjectSelectViewController *icdSelectController = [[ObjectSelectViewController alloc] init];
				icdSelectController.sectionObj = sectionObj;
				icdSelectController.censusObj = self.censusObj;
				icdSelectController.useCrosswalk = YES;
				icdSelectController.primary = isPrimary;
				icdSelectController.encounterId = encounterId;
				
				UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:icdSelectController];
				[icdSelectController release];
				[self presentModalViewController:navController animated:YES];
				[navController release];
			}
			
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
	}
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [self.tableView reloadData];
	
}


#pragma mark -
#pragma mark Private

- (void)pickerDataForList {
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat:@"MM/dd/yy"];
	
	NSTimeInterval admitDateInSecs = self.censusObj.admitDate;
	NSTimeInterval dischargeDateInSecs = self.censusObj.dischargeDate;
	NSDate *admitDate = [NSDate dateWithTimeIntervalSince1970:admitDateInSecs];
	NSDate *dischargeDate = nil;
	
	if(dischargeDateInSecs>0){
		dischargeDate = [NSDate dateWithTimeIntervalSince1970:dischargeDateInSecs];
		//find out how many days between admit and discharge date only if the discharge date is filled in
		days = [admitDate differenceInDaysTo:dischargeDate];
	}else{
		//find out how many days since admit date
		days = [admitDate differenceInDaysTo:[NSDate dateWithoutTime]];
	}
	
	[pickerViewArray addObject:NSLocalizedString(@"ALL", @"ALL")];
	NSDate *date1 = nil;
	if(dischargeDateInSecs>0)
		date1 = dischargeDate;
	else
		date1 = [NSDate dateWithoutTime];
	for(int i=0;i<=days;i++){
		NSDate *date2 = [date1 dateByAddingDays:-i];
		[pickerViewArray addObject:[format stringFromDate:date2]];
	}			
}
- (void)allCptViewClicked {
    CodesByDateViewController *codesController = [[CodesByDateViewController alloc] init];
    codesController.previousControllerTitle = NSLocalizedString(@"Charges", @"Charges");
    [self.navigationController pushViewController:codesController animated:YES];
    [codesController release];
}

#pragma mark -
#pragma mark View lifecycle


- (void)loadView {
    [super loadView];
    _openedSection = 0;
	
	pickerViewArray = [[NSMutableArray alloc] init];
	
	// init a horizontal picker view
	horizontalPicker = [[[HorizontalPickerView alloc] initWithFrame: CGRectMake(0.0f, 46.0f, 320, 55)] autorelease];
	horizontalPicker.rowWidth = 90.0f;
	horizontalPicker.delegate = self;
	horizontalPicker.dividerView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"picker-selector"]] autorelease];
	
	[self.view addSubview: horizontalPicker];
	
	//get the number of dates between admit and current dates
	//for picker view for selecting the date of service
	[self pickerDataForList];
	_selectedDos = [pickerViewArray objectAtIndex:1];
	self.censusObj.selectedDos = [Helper conevrtDosToTimeInterval:_selectedDos];
	NSLog(@"_selectedDos %@",_selectedDos);
	
	[horizontalPicker reload];
	//[horizontalPicker selectRow:1 animated:NO];
	
	NSLog(@"self.censusObj.dateOfService %.0f",self.censusObj.dateOfService);
	lastSelectedPickerRow=1;
	
	for (int i=1;i<[pickerViewArray count];i++) {
		NSString *strDos = [pickerViewArray objectAtIndex:i];
		NSTimeInterval dos = [Helper conevrtDosToTimeInterval:strDos];
		NSLog(@"strDos %@",strDos);
		NSLog(@"dos %.0f",dos);
		if(self.censusObj.dateOfService == dos){
			lastSelectedPickerRow=i;
			break;
		}
	}
	Patient_old *patient = [Patient_old getPatientToDisplay:self.censusObj.patientId];
	if(patient){
		_patientView = [self patientHeader:self.censusObj
							 dateOfService:self.censusObj.selectedDos
								  delegate:self];
		[_patientView setState:UIControlStateDisabled];	
		[self.view addSubview:_patientView];
    }
	
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 374, 320, 42)];
    LightGreyGlassGradientView *bgView = [[LightGreyGlassGradientView alloc] initWithFrame:bottomView.bounds];
    [bottomView addSubview:bgView];
    [bgView release];
    
    _notesButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
    _notesButton.btnType = StretchableButton25;
    _notesButton.tag = 21;
    _notesButton.frame = CGRectMake(10, 0, 65, 42);
    [_notesButton setTitle:NSLocalizedString(@"Notes", @"Notes") forState:UIControlStateNormal];
    _notesButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
    [_notesButton addTarget:self action:@selector(showNotesInfo:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_notesButton];
	
    self.chatButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
    self.chatButton.btnType = StretchableButton25;
    self.chatButton.tag = 22;
    self.chatButton.frame = CGRectMake(80, 0, 65, 42);
    [self.chatButton setTitle:NSLocalizedString(@"Chat", @"Chat") forState:UIControlStateNormal];
    self.chatButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
    [self.chatButton addTarget:self action:@selector(showChat:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:self.chatButton];
	
	/*
	 _editButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
	 _editButton.btnType = StretchableButton25;
	 _editButton.tag = 23;
	 _editButton.frame = CGRectMake(175, 0, 65, 42);
	 [_editButton setTitle:NSLocalizedString(@"Edit", @"Edit") forState:UIControlStateNormal];
	 [_editButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateSelected];
	 _editButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
	 [_editButton addTarget:self action:@selector(toggleTableEdit:) forControlEvents:UIControlEventTouchUpInside];
	 [bottomView addSubview:_editButton];*/
	
    _copyButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
    _copyButton.btnType = StretchableButton25;
    _copyButton.tag = 23;
    _copyButton.frame = CGRectMake(175, 0, 65, 42);
    [_copyButton setTitle:NSLocalizedString(@"Copy", @"Copy") forState:UIControlStateNormal];
    _copyButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
    [_copyButton addTarget:self action:@selector(copyPreviousCharge:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_copyButton];
	
    _finishButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
    _finishButton.btnType = StretchableButton25;
    _finishButton.tag = 24;
    _finishButton.frame = CGRectMake(245, 0, 65, 42);
    [_finishButton setTitle:NSLocalizedString(@"Finish", @"Finish") forState:UIControlStateNormal];
    _finishButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
	//    _finishButton.enabled = NO;
    [_finishButton addTarget:self action:@selector(markEncounterComplete:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_finishButton];
    
    [self.view addSubview:bottomView];
    [bottomView release];
	
    // 44 is toolbar height
    CGFloat tableHeight = self.view.bounds.size.height - 186;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 102.0f, self.view.bounds.size.width, tableHeight) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
	
    //define the toolbar for button actions to update the patient info and add/update notes
    UIToolbar *toolbarActions=[[UIToolbar alloc] initWithFrame:CGRectMake(0,self.view.bounds.size.height - 44 - 44,self.view.bounds.size.width,44)];
    NSMutableArray *toolbarActionItems=[[NSMutableArray alloc] init];
    UIBarButtonItem *toolbarAction_ButtonItem_0=[[[UIBarButtonItem alloc] initWithTitle:@"Patient Info" style:1  target:self action:@selector(showPatientInfo:)] autorelease];
    [toolbarActionItems addObject:toolbarAction_ButtonItem_0];
    UIBarButtonItem *toolbarAction_ButtonItem_1=[[[UIBarButtonItem alloc] initWithTitle:@"Notes" style:1  target:self action:@selector(showNotesInfo:)] autorelease];
    [toolbarActionItems addObject:toolbarAction_ButtonItem_1];
    
    [toolbarActions setItems:toolbarActionItems];
    [toolbarActionItems release];
    toolbarActions.tag=0;
    toolbarActions.backgroundColor=[UIColor whiteColor];
    [toolbarActions release];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
    _tableView.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
	
	
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Charges", @"Charges") 
                                                          buttonImage:[UIImage imageNamed:@"btn-add"] 
                                                         buttonAction:@selector(addNewCpt:)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _showAllSections = NO;
    //change the backgroud color to grey
	//    self.view.backgroundColor=[UIColor groupTableViewBackgroundColor];
	//    self.navigationItem.title=patientName;
}
- (void)viewDidUnload
{
	[_censusObj release];
	[pickerViewArray release];
    [_tableView release];
    [_notesButton release];
    [self.chatButton release];
    //[_editButton release];
	[_copyButton release];
    [_finishButton release];
    [_patientView release];
    [arrayToDisplay release];
	[apptObj release];
    [_tableView release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[horizontalPicker reload];
	[horizontalPicker selectRow:lastSelectedPickerRow animated:NO];
	[horizontalPicker forceMagnifierReresh];
	_selectedDos = [pickerViewArray objectAtIndex:lastSelectedPickerRow];
	self.censusObj.selectedDos = [Helper conevrtDosToTimeInterval:_selectedDos];
	NSLog(@"_selectedDos: %@",_selectedDos);
	[self refreshCodesData];
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setNavigationBarBackgroundImage];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        // View is disappearing because a new view controller was pushed onto the stack

    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        // View is disappearing because it was popped from the stack
        // Push changes (if any) to data server
        [[Outbound sharedOutbound] sendCensusesToSuperNode];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Actions

- (void) addNewCpt:(id) sender
{
	//self.censusObj.dateOfService = [Helper conevrtDosToTimeInterval:_selectedDos];
	
    AddCptViewController *newCptView = [[[AddCptViewController alloc] init] autorelease];
	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:newCptView];
	[self presentModalViewController:navigation animated:YES];
	[navigation release];
}

- (IBAction)insertIcdRows:(id)sender {
	
	UIButton *theButton = (UIButton*)sender;
	UITableViewCell *cell = (UITableViewCell*)[theButton superview];
	NSIndexPath *thisIndexPath = [self.tableView indexPathForCell:cell];
    
    //Get the cpt dictionary object from the array at the section index
    NSDictionary *dictObj = [arrayToDisplay objectAtIndex:thisIndexPath.section];
    //Get the cpt object with the key "cpt"
    EncounterCpt *sectionObj = [dictObj objectForKey:@"cpt"];
	//Get the Icd count to figure out if its primary.
	NSMutableArray *icdArray = [dictObj objectForKey:@"icds"];
	//If the count is zero, then its first one, set primary to TRUE
	//otherwise set FALSE
	[icdArray retain];
	BOOL isPrimary = YES;
	if([icdArray count] > 0)
		isPrimary = NO;
	[icdArray release];
    
    // MZ: selecting ICD styling + massive refactoring
    ObjectSelectViewController *icdSelectController = [[ObjectSelectViewController alloc] init];
    icdSelectController.sectionObj = sectionObj;
	icdSelectController.censusObj = self.censusObj;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:icdSelectController];
    [icdSelectController release];
    [self presentModalViewController:navController animated:YES];
    [navController release];
}

- (void) copyPreviousCharge:(id) sender
{
	if([_selectedDos isEqualToString:NSLocalizedString(@"ALL",@"ALL")]){
	}else{
		if(lastSelectedPickerRow < [pickerViewArray count]){
			NSMutableArray *prevCharges=nil;
			for (int i=lastSelectedPickerRow+1; i<[pickerViewArray count]; i++) {
				NSString *prevDos = [pickerViewArray objectAtIndex:i];
				
				NSTimeInterval prevdosInterval = [Helper conevrtDosToTimeInterval:prevDos];
				prevCharges = [[EncounterCpt getChargesToDisplayForCensus:self.censusObj andDos:prevdosInterval] retain];
				if(prevCharges!=nil && [prevCharges count]>0){
					[Encounter_old copyCharge:[prevCharges objectAtIndex:0]  andCensusObj:self.censusObj andCurrentDos:self.censusObj.selectedDos];
					[horizontalPicker reload];
					[horizontalPicker selectRow:lastSelectedPickerRow animated:NO];
					[horizontalPicker forceMagnifierReresh];
					[self refreshCodesData];
					break;
				}
			}
		}
	}
}

- (void)presentIcdDetails:(id)sender {
    UIButton *btn = sender;
    UITableViewCell *cell = (UITableViewCell*)btn.superview;
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    NSDictionary *dictObj = [arrayToDisplay objectAtIndex:indexPath.section];
    IcdDetailsView *detailsController = [[IcdDetailsView alloc] init];
    detailsController.previousControllerTitle = NSLocalizedString(@"Charges", @"Charges");
    if (indexPath.row == 0) {
        EncounterCpt *sectionObj = [dictObj objectForKey:@"cpt"];
        Cpt *cpt = [Cpt getCptObjectForCptCode:sectionObj.cptCode];
        detailsController.obj = cpt;
    }
    else {
        NSMutableArray *rowArray = [dictObj objectForKey:@"icds"];
        if([rowArray count]>0){
            EncounterIcd *rowObj = [rowArray objectAtIndex:indexPath.row-1];
            Icd *selectedIcd = [Icd getIcdObjectForIcdcode:rowObj.icdCode];
            detailsController.obj = selectedIcd;
        }
    }
    if (detailsController.obj != nil) {
		
        //get the superbill for the given physician and facility type id
        //NSInteger superbillId = [SuperbillCpt getSuperbillId:self.censusObj.physicianNpi];
		NSInteger superbillId = 0;
		detailsController.censusObj = self.censusObj;
		detailsController.superbillId = superbillId;
        [self.navigationController pushViewController:detailsController animated:YES];
    }
	[detailsController release];	
}


- (void)showChat:(id)sender
{
    [super showChat];
    //for 607. will continue latter
    /*Patient *patient = [Patient getPatientToDisplay:self.censusObj.patientId];
    NSArray *conversations = [DBHelperConversation getConversationsWithSubject:patient.fullName];*/
}

- (void)updateTableWithOptions:(NSDictionary *)options {
    NSArray *indexPathsToInsert = [options valueForKey:@"pathsToInsert"];
    NSArray *indexPathsToDelete = [options valueForKey:@"pathsToDelete"];
    
    
    [_tableView beginUpdates];
    if (indexPathsToInsert != nil && [indexPathsToInsert count] > 0) {
        UITableViewRowAnimation insertAnimation = UITableViewRowAnimationTop;
        NSNumber *insertAnimationNumber = [options valueForKey:@"insertAnimation"];
        if (insertAnimationNumber != nil) {
            insertAnimation = [insertAnimationNumber integerValue];
        }
        [_tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    }
    if (indexPathsToDelete != nil && [indexPathsToDelete count] > 0) {
        UITableViewRowAnimation deleteAnimation = UITableViewScrollPositionBottom;
        NSNumber *deleteAnimationNumber = [options valueForKey:@"deleteAnimation"];
        if (deleteAnimationNumber != nil) {
            deleteAnimation = [deleteAnimationNumber integerValue];
        }
        [_tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    }
    [_tableView endUpdates];
    
}

- (void)expandAllSections {
    NSMutableArray *pathsToInsert = [NSMutableArray array];
    for (int i = 0; i < _tableView.numberOfSections; i++) {
        if (i != _openedSection) {
            UITableViewCell *cellClosed = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
            ((CPTTableViewCell *)cellClosed).opened = YES;
            NSDictionary  *sectionObj = [arrayToDisplay objectAtIndex:i];
            //get the corresponding icd codes with the key "icds"
            NSArray *rowArray = [sectionObj objectForKey:@"icds"];
            //if there are icds, return the number of icds plus one to display the cpt in first row;
            // second row to add new icd
            int rowCount = [rowArray count] + 2;
            for (int j = 1; j < rowCount; j++) {
                [pathsToInsert addObject:[NSIndexPath indexPathForRow:j inSection:i]];
            }
			
        }
        
    }
    NSDictionary *updateDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                      pathsToInsert, @"pathsToInsert",
                                      nil];
    [self updateTableWithOptions:updateDictionary];
}

- (void)collapseAllSections
{
    NSMutableArray *pathsToDelete = [NSMutableArray array];
    for (int i = 0; i < _tableView.numberOfSections; i++)
    {
        if (i != _openedSection)
        {
            UITableViewCell *cellClosed = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
            ((CPTTableViewCell *)cellClosed).opened = NO;
            NSDictionary  *sectionObj = [arrayToDisplay objectAtIndex:i];
            //get the corresponding icd codes with the key "icds"
            NSArray *rowArray = [sectionObj objectForKey:@"icds"];
            //if there are icds, return the number of icds plus one to display the cpt in first row;
            // second row to add new icd
            int rowCount = [rowArray count] + 2;
            for (int j = 1; j < rowCount; j++)
            {
                [pathsToDelete addObject:[NSIndexPath indexPathForRow:j inSection:i]];
            }
            
        }
    }
    NSDictionary *updateDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                      pathsToDelete, @"pathsToDelete",
                                      nil];
    [self updateTableWithOptions:updateDictionary];
    
}

- (void)showNotesInfo:(id)sender
{
    EncounterNotesViewController *tempController = [[EncounterNotesViewController alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Charges", @"Charges");
	tempController.censusObj = self.censusObj;
	tempController.dateOfService = self.censusObj.selectedDos;
    [self.navigationController pushViewController:tempController animated:YES];
    [tempController release];
}


- (void)setFinishButtonState {
    BOOL enabled = NO;
	if(self.censusObj.selectedDos>0){
		Encounter_old *encounterObj = [Encounter_old getEncounterObjForCensus:self.censusObj.censusId :self.censusObj.physicianNpi :self.censusObj.selectedDos];
		if(encounterObj.status == EncounterStatusComplete){
			enabled = NO;
		}else {
			if ([arrayToDisplay count] > 0) {
				BOOL subEnabled = NO;
				for (NSDictionary *dict in arrayToDisplay) {
					// MZ: check if all CPTs have at least one ICD associated
					// RA: changed the logic to count the ICDs instead. 
					// becasue if the last cpt does not have ICD, the whole thing
					// is set to disabled
					// RA: Changed the logic again based on David's feedback.
					// need to disable the Finish button if any of cpt does not have
					// associated Icds.
					if ([[dict valueForKey:@"icds"] count] > 0) {
						subEnabled = YES;
					}else{
						subEnabled = NO;
					}
				}
				enabled = subEnabled;
			}else {
				_notesButton.enabled = NO;
			}
		}
	}
	_finishButton.enabled = enabled;
}

#pragma mark -
#pragma mark PatientListViewDelegate

- (void)patientViewClicked:(Patient_old *)patient {
    RoundViewController *patientView = [[RoundViewController alloc] init];
	PhysicianPref *physicianPref = [PhysicianPref getPhysicianPrefs:self.censusObj.physicianNpi];
	patientView.physicianPref = physicianPref;
    patientView.census = self.censusObj;
	patientView.selectedDos = [Helper conevrtDosToTimeInterval:_selectedDos];
    patientView.currentViewMode = QliqModelViewModeView;
    patientView.previousControllerTitle = NSLocalizedString(@"Charges", @"Charges");
    [self.navigationController pushViewController:patientView animated:YES];
    [patientView release];
}

- (void)patientDateClicked:(Patient_old *)patient {
    CodesByDateViewController *codesController = [[CodesByDateViewController alloc] init];
    codesController.previousControllerTitle = NSLocalizedString(@"Charges", @"Charges");
    [self.navigationController pushViewController:codesController animated:YES];
    [codesController release];
}

@end
