//
//  PatientDemographicsViewController.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "PatientDemographicsViewController.h"
#import "DBHelperNurse.h"
#import "Helper.h"

@implementation PatientDemographicsViewController
@synthesize patient = patient_;

-(id) init
{
    self = [super init];
    if(self)
    {
		patientContactsArray = [[NSMutableArray alloc] init];
    }
    return self;
}
-(void) dealloc
{
    //TIP:
    [patient_ release];
	[patientContactsArray release];
	[censusObj release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    patientDemographicsView = [[PatientDemographicsView alloc] init];
    patientDemographicsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    patientDemographicsView.autoresizesSubviews = YES;
    patientDemographicsView.patientName = @"Patient name";
    patientDemographicsView.infoTable.delegate = self;
    patientDemographicsView.infoTable.dataSource = self;
    self.view = patientDemographicsView;
}

-(void) refreshData
{
    //TIP:
	censusObj = [[Census_old getCensusObject:self.patient.censusId] retain];
	patientContactsArray = [[DBHelperNurse getPatientContacts:self.patient.patientId] retain];
}


-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:@"Patient Demographics" buttonImage:nil buttonAction:nil];
	[self refreshData];
}
/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section==0)
		return [patientContactsArray count];
	else
		return 1;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"infoTableViewCell";
    PatientDemographicsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[PatientDemographicsTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId]autorelease];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    PatientDemographicsTableCellLabelGroup *group = [cell labelGroupAtIndex:0];
    switch (indexPath.section) 
    {
		case 0:
		{
			PatientContact *patientContactObj = [patientContactsArray objectAtIndex:indexPath.row];
			group.key.text = @"Name";
			group.value.text = patientContactObj.name;
			
			group = [cell labelGroupAtIndex:1];
			group.key.text = @"Relation";
			group.value.text = patientContactObj.relation;
			
			group = [cell labelGroupAtIndex:2];
			group.key.text = @"Phone";
			group.value.text = patientContactObj.phone;
			cell.imageView.image = [UIImage imageNamed:@"phone_blue.png"];
		}
			break;
		case 1:
		{
			group.key.text = @"Age • Sex";
			NSInteger age = [Helper age:self.patient.dateOfBirth];
			NSString *strAge = nil;
			if(age==0)
				strAge = @"";
			else
				strAge = [NSString stringWithFormat:@"%d",age];
			group.value.text = [NSString stringWithFormat:@"%@ • %@",strAge,self.patient.gender];
			
			group = [cell labelGroupAtIndex:1];
			group.key.text = @"DOB";
			group.value.text = [Helper getDateFromInterval:self.patient.dateOfBirth];
			
			group = [cell labelGroupAtIndex:2];;
			group.key.text = @"Ethnicity";
			group.value.text = self.patient.race;
		}
			break;
		case 2:
		{
			group.key.text = @"Facility";
			group.value.text = censusObj.facilityName;
			
			group = [cell labelGroupAtIndex:1];
			group.key.text = @"MRN";
			group.value.text = censusObj.mrn;
			
			group = [cell labelGroupAtIndex:2];
			group.key.text = @"Room";
			group.value.text = censusObj.room;
		}
			break;
		case 3:
		{
			group.key.text = @"Admit Date";
			group.value.text = [Helper getDateFromInterval:censusObj.admitDate];
			
			group = [cell labelGroupAtIndex:1];
			group.key.text = @"Discharge Date";
			group.value.text = [Helper getDateFromInterval:censusObj.dischargeDate];
			
			group = [cell labelGroupAtIndex:2];
			group.key.text = @"Referring Physician";
			group.value.text = censusObj.referringPhysicianName;
		}
			break;
		default:
			break;
	}
	
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25.0;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TableSectionHeaderWithLabel *header = [[TableSectionHeaderWithLabel alloc] init];
    header.sectionIndex = section;
    header.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
    header.textLabel.backgroundColor = [UIColor clearColor];
    header.textLabel.textColor = [UIColor whiteColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:10.0];
    
    switch (section) 
    {
        case 0: header.textLabel.text = @"Contact Information"; break;
        case 1: header.textLabel.text = @"Demographics"; break;
        case 2: header.textLabel.text = @"Facility information"; break;
        case 3: header.textLabel.text = @"Visit information";break;
        default:
            break;
    }
    return [header autorelease];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
