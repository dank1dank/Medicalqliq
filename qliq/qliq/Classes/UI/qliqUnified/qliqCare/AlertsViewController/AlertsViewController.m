//
//  AlertsViewController.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "AlertsViewController.h"

@interface AlertsViewController()

-(BOOL) hideVisitOrHandoffButton;
-(NSMutableDictionary*) cellsForHandoffState:(NurseHandoffState)state withSelectedItem:(NSIndexPath*)indexPath;

@end

@implementation AlertsViewController

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
    alertsView = [[FloorPatientsView alloc] init];
    alertsView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    alertsView.autoresizesSubviews = YES;
    alertsView.patientsTable.delegate = self;
    alertsView.patientsTable.dataSource = self;
    alertsView.tabView.delegate = self;
    alertsView.hospitalName = @"Nurse";
    self.view = alertsView;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/


-(void) viewWillAppear:(BOOL)animated
{
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:NSLocalizedString(@"Alerts", @"Alerts") 
                                                          buttonImage:[UIImage imageNamed:@"btn-add"] 
                                                         buttonAction:nil];
}

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
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //TIP:
    //[patientsArray count];
    return 0;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"FloorTableViewCell";
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[PatientTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId]autorelease];
        cell.delegate = self;
    }
    
    /* TIP:
     Patient *p = [patientsArray objectAtIndex:indexPath.row];
     and fill cell data with this object
     */
    
    cell.lblPatientName.text = @"Patient Name";
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark -
#pragma mark PatientsTableViewCellDelegate

-(BOOL) shouldShowVisitStatusButtonForCell:(PatientTableViewCell *)cell
{
    [self hideVisitOrHandoffButton];
    return YES;
}

-(NSString*) visitStatusButtonTitleForCell:(PatientTableViewCell *)cell
{
    return @"Clear";
}

-(void) visitButtonPressedOnCell:(PatientTableViewCell *)cell
{
    [self hideVisitOrHandoffButton];
}


-(BOOL) shouldShowHandoffButtonForCell:(PatientTableViewCell *)cell
{
    [self hideVisitOrHandoffButton];
    return YES;
}

-(NSString*) handoffButtonTitleForCell:(PatientTableViewCell *)cell
{
    state = NurseHandoffStateGiveStart;
    return @"Give";
}

-(void) handoffButtonPressedOnCell:(PatientTableViewCell *)cell
{
    SelectPersonViewController *ctrl = [[SelectPersonViewController alloc] init];
    ctrl.delegate = self;
    ctrl.multipleSelection = YES;
    NSMutableDictionary *selectPersonCells = [self cellsForHandoffState:state withSelectedItem:[alertsView.patientsTable indexPathForCell:cell]];
    if(state == NurseHandoffStateGiveStart)
    {
        //ctrl.nextButtonType = SelectPersonNextButton;
        state = NurseHandoffStateGiveSelectPatients;
    }
    if(state == NurseHandoffStateTakeStart)
    {
        //ctrl.nextButtonType = SelectPersonNextButtonTake;
        state = NurseHandoffStateTakeSelectPatients;
    }
    ctrl.cells = selectPersonCells;
    [self hideVisitOrHandoffButton];
    [[self navigationController] pushViewController:ctrl animated:YES];
    [ctrl release];
}

#pragma mark -
#pragma mark Handoff handling

-(NSMutableDictionary*) cellsForHandoffState:(NurseHandoffState)state withSelectedItem:(NSIndexPath*)selectedItemIndexPath
{
    switch(state)
    {
        case NurseHandoffStateGiveStart:
        {
            NSMutableDictionary *selectPersonCells = [[NSMutableDictionary alloc] init];
            NSMutableArray *sections = [[[NSMutableArray alloc] init] autorelease];
            int section_counter = 0;
            NSInteger num_sections = [self numberOfSectionsInTableView:alertsView.patientsTable];
            for(int i = 0; i<num_sections; i++)
            {
                NSMutableDictionary *sectionDict = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *headerCell = [[NSMutableDictionary alloc] init];
                
                [headerCell setObject:@"Select all" forKey:@"title"];
                [sectionDict setObject:headerCell forKey:@"header"];
                [headerCell release];
                
                NSMutableArray *cells = [[NSMutableArray alloc] init];
                int row_counter = 0;
                NSInteger num_rows = [self tableView:alertsView.patientsTable numberOfRowsInSection:num_sections];
                for(int j = 0; j<num_rows; j++)
                {
                    //if([self canBeGiven:census])
                    {
                        NSMutableDictionary *cellDict = [[NSMutableDictionary alloc] init];
                        [cellDict setObject:@"Patient name" forKey:@"title"];
                        if(selectedItemIndexPath != nil)
                        {
                            if(section_counter == selectedItemIndexPath.section && row_counter == selectedItemIndexPath.row)
                            {
                                [cellDict setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
                            }
                            else
                            {
                                [cellDict setObject:[NSNumber numberWithBool:NO] forKey:@"selected"];
                            }
                        }
                        //[cellDict setObject:[NSNumber numberWithInt:census.patientId] forKey:@"id"];
                        [cells addObject:cellDict];
                        [cellDict release];
                    }
                    row_counter ++;
                }
                [sectionDict setObject:cells forKey:@"cells"];
                [cells release];
                
                [sections addObject:sectionDict];
                [sectionDict release];
                section_counter ++;
            }
            [selectPersonCells setObject:sections forKey:@"sections"];
            return [selectPersonCells autorelease];
        }
        case NurseHandoffStateGiveSelectPatients:
        {
            NSMutableDictionary *selectPersonCells = [[NSMutableDictionary alloc] init];
            NSMutableArray *sections = [[NSMutableArray alloc] init];
            NSMutableDictionary *sectionDict = [[NSMutableDictionary alloc] init];
            
            NSMutableDictionary *headerCell = [[NSMutableDictionary alloc] init];
            [headerCell setObject:@"Select provider" forKey:@"title"];
            [sectionDict setObject:headerCell forKey:@"header"];
            [headerCell release];
            
            /*Physician *me = [Physician getPhysician:[Helper getUsername]];
            NSArray *groupmates = [Physician getGroupmatesForPhysicianWithNPI:me.physicianNpi];*/
            NSMutableArray *cells = [[NSMutableArray alloc] init];
            /*for(Physician *groupmate in groupmates)
            {
                NSMutableDictionary *cellDict = [[NSMutableDictionary alloc] init];
                [cellDict setObject:groupmate.name forKey:@"title"];
                [cellDict setObject:groupmate.specialty forKey:@"description"];
                [cellDict setObject:[NSNumber numberWithDouble:groupmate.physicianNpi] forKey:@"id"];
                [cells addObject:cellDict];
                [cellDict release];
            }*/
            [sectionDict setObject:cells forKey:@"cells"];
            [cells release];
            
            [sections addObject:sectionDict];
            [sectionDict release];
            [selectPersonCells setObject:sections forKey:@"sections"];
            return [selectPersonCells autorelease];
            
        }break;
    }
    return nil;
}
            

-(void) nextButtonPressedForSelectPersonViewController:(SelectPersonViewController *)selectPersonViewController
{
    switch(state)
    {
        case NurseHandoffStateGiveSelectPatients:
        {
            SelectPersonViewController *ctrl = [[SelectPersonViewController alloc] init];
            ctrl.delegate = self;
            ctrl.multipleSelection = NO;
            //ctrl.nextButtonType = SelectPersonNextButtonGive;
            ctrl.cells = [self cellsForHandoffState:state withSelectedItem:nil];
            state = NurseHandoffStateGiveSelectNurse;
            /*[selectedPatientsIds release];
            selectedPatientsIds = nil;
            selectedPatientsIds = [selectPersonViewController getSelectedItemsIds];
            [selectedPatientsIds retain];*/
            [[self navigationController] pushViewController:ctrl animated:YES];
            [ctrl release];
        }break;
        case NurseHandoffStateGiveSelectNurse:
        {
            /*NSNumber* selectedPhysicianID = [[[selectPersonViewController getSelectedItemsIds] allObjects] objectAtIndex:0];
            [self processGive:selectedPatientsIds physicianId:selectedPhysicianID];
            [self.navigationController popToViewController:self animated:YES];*/
        }
        case NurseHandoffStateTakeSelectPatients:
        {
            /*[self processTake:[selectPersonViewController getSelectedItemsIds]];
            [self.navigationController popToViewController:self animated:YES];*/
        }
    }
}

-(void) cancelButtonPressedForSelectPersonViewController:(SelectPersonViewController *)selectPersonViewController
{
    switch (state)
    {
        case NurseHandoffStateGiveStart:{}break;
        case NurseHandoffStateGiveSelectPatients:{state = NurseHandoffStateGiveStart;}break;
        case NurseHandoffStateGiveSelectNurse:{state = NurseHandoffStateGiveSelectPatients;}break;
        case NurseHandoffStateTakeSelectPatients:{state = NurseHandoffStateTakeStart;}break;
        default: break;
    }
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark Private

-(BOOL) hideVisitOrHandoffButton
{
    NSInteger sections = [self numberOfSectionsInTableView:alertsView.patientsTable];
    for(NSInteger section = 0; section<sections; section++)
    {
        NSInteger rows = [self tableView:alertsView.patientsTable numberOfRowsInSection:section];
        for(NSInteger row = 0; row < rows; row++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            PatientTableViewCell *cell = (PatientTableViewCell*)[alertsView.patientsTable cellForRowAtIndexPath:indexPath];
            if(cell.visitStatusButtonVisible)
            {
                [cell setVisitStatusButtonVisible:NO animated:YES];
                return YES;
            }
            if(cell.handOffButtonVisible)
            {
                [cell setHandOffButtonVisible:NO animated:YES];
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark -
#pragma mark NurseTabViewDelegate

-(void) chatButtonPressed
{
    [self showChat];
}
@end
