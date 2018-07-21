//
//  ICDSelectViewController.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "ObjectSelectViewController.h"
#import "ObjectListViewController.h"
//#import "ChargeCaptureAppDelegate.h"
#import "Census_old.h"
#import "EncounterCpt.h"
#import "EncounterIcd.h"
#import "SelectIcdTabView.h"
#import "Icd.h"
#import "PatientHeaderView.h"
#import "Patient_old.h"
#import "IcdDetailsView.h"
#import "Cpt.h"
#import "Patient_old.h"
#import "Encounter_old.h"
#import "AddCptViewController.h"
#import "RoundViewController.h"

@interface ObjectSelectViewController (Private) <ICDListViewDelegate, PatientHeaderViewDelegate>

- (void)selectTab:(id)sender;

@end

@implementation ObjectSelectViewController

@synthesize primary = _primary;
@synthesize censusObj = _censusObj;
@synthesize sectionObj = _sectionObj;
//@synthesize dateOfService = _dateOfService;
@synthesize useCrosswalk;
@synthesize showingCPTs;
@synthesize encounterId,superbillId;
//@synthesize patient, encounterId,physicianNpi,superbillId,censusId;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	[favList release];
	[crosswalkList release];
    [super dealloc];
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
    [super loadView];
	
    PatientHeaderView *patientView = [self patientHeader:self.censusObj dateOfService:self.censusObj.dateOfService delegate:self];
	[patientView setState:UIControlStateDisabled];
    [self.view addSubview:patientView];
	/*
	 [self.view addSubview:[self patientHeader:self.patient
	 dateOfService:_dateOfService 
	 delegate:self]];
	 */
    favList = [[NSMutableArray alloc] init];
    crosswalkList = [[NSMutableArray alloc] init];
	
    mainTabView = [[SelectIcdTabView alloc] initWithFrame:CGRectMake(0,366,320,50) withCrosswalk:self.useCrosswalk];
    mainTabView.favoritesButton.tag = 1;
    mainTabView.allButton.tag = 3;
    [mainTabView.favoritesButton addTarget:self action:@selector(selectTab:) forControlEvents:UIControlEventTouchUpInside];
    [mainTabView.allButton addTarget:self action:@selector(selectTab:) forControlEvents:UIControlEventTouchUpInside];
    if (self.useCrosswalk) {
        mainTabView.crosswalkButton.tag = 2;
        [mainTabView.crosswalkButton addTarget:self action:@selector(selectTab:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.view addSubview:mainTabView];
    
	
    if (self.isShowingCPTs) {
        //masterList = [Cpt getMasterCptsToDisplay];
		[favList release];
        favList = [[Cpt getFavoriteCptsToDisplay:self.superbillId] retain];
        self.navigationItem.title = NSLocalizedString(@"CPT Entry", @"CPT Entry");
    }
    else {
		[favList release];
        favList = [[Icd getFavoriteIcdsToDisplay:self.censusObj.physicianNpi] retain];
        if (self.useCrosswalk) {
			[crosswalkList release];
            crosswalkList = [[Icd getCrosswalkIcdsToDisplay:self.sectionObj.encounterCptId] retain];
        }
        self.navigationItem.title = NSLocalizedString(@"ICD Entry", @"ICD Entry");
    }
	
    _masterController = [[ObjectListViewController alloc] init];
    [_masterController setEncounterCptId:self.sectionObj.encounterCptId];
	[_masterController setPhysicianNpi:self.censusObj.physicianNpi];
	[_masterController setIsPrimary:self.isPrimary];
    _masterController.delegate = self;
    _masterController.showingCPTs = self.showingCPTs;
	
    _favoritesController = [[ObjectListViewController alloc] init];
    [_favoritesController setEncounterCptId:self.sectionObj.encounterCptId];
    [_favoritesController setListOfIcdCodes:favList];
	[_favoritesController setPhysicianNpi:self.censusObj.physicianNpi];
	[_favoritesController setIsPrimary:self.isPrimary];
    _favoritesController.delegate = self;
    _favoritesController.showingCPTs = self.showingCPTs;
	
    [self.view addSubview:_masterController.view];
    [self.view addSubview:_favoritesController.view];
    if (self.useCrosswalk) {
        _crosswalkController = [[ObjectListViewController alloc] init];
        [_crosswalkController setEncounterCptId:self.sectionObj.encounterCptId];
        [_crosswalkController setListOfIcdCodes:crosswalkList];
        [_crosswalkController setPhysicianNpi:self.censusObj.physicianNpi];
        [_crosswalkController setIsPrimary:self.isPrimary];
        _crosswalkController.delegate = self;
        [self.view addSubview:_crosswalkController.view];
    }
    
    CGRect frame = _masterController.view.frame;
    frame.origin.y = 46;
    frame.size.height = 366;
    _masterController.view.frame = frame;
	
    frame = _favoritesController.view.frame;
    frame.origin.y = 46;
    frame.size.height = 320;
    _favoritesController.view.frame = frame;
	
    if (self.useCrosswalk) {
        frame = _crosswalkController.view.frame;
        frame.origin.y = 46;
        frame.size.height = 320;
        _crosswalkController.view.frame = frame;
    }
	
    if(self.useCrosswalk && [crosswalkList count] > 0) {
        [self selectTab:mainTabView.crosswalkButton];
    }
    else {
        if([favList count]>0) {
            [self selectTab:mainTabView.favoritesButton];
        }
        else {
            [self selectTab:mainTabView.allButton];
        }
    }
    
    UIButton* cancelButtonView = [UIButton buttonWithType: UIButtonTypeCustom];
    UIImage* cancelButtonImage = [[UIImage imageNamed: @"bg-cancel-btn.png"] stretchableImageWithLeftCapWidth: 17 topCapHeight: 0];
    [cancelButtonView setBackgroundImage: cancelButtonImage
                                forState: UIControlStateNormal];
    [cancelButtonView setTitle: @"Cancel" forState: UIControlStateNormal];
    cancelButtonView.titleLabel.font = [UIFont boldSystemFontOfSize: 12.0f];
    cancelButtonView.frame = CGRectMake(0.0f, 0.0f, 80.0f, 42.0f);
    [cancelButtonView addTarget: self 
                         action: @selector(cancelSelectIcd:)
               forControlEvents: UIControlEventTouchUpInside];
    UIBarButtonItem* cancelBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView: cancelButtonView] autorelease];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    
    
    UIButton* doneButtonView = [UIButton buttonWithType: UIButtonTypeCustom];
    UIImage* doneButtonImage = [[UIImage imageNamed: @"bg-cancel-btn.png"] stretchableImageWithLeftCapWidth: 17 topCapHeight: 0];
    [doneButtonView setBackgroundImage: doneButtonImage
                              forState: UIControlStateNormal];
    [doneButtonView setTitle: @"Done" forState: UIControlStateNormal];
    doneButtonView.titleLabel.font = [UIFont boldSystemFontOfSize: 12.0f];
    doneButtonView.frame = CGRectMake(0.0f, 0.0f, 80.0f, 42.0f);
    [doneButtonView addTarget: self 
                       action: @selector(doneSelectIcd:)
             forControlEvents: UIControlEventTouchUpInside];
    _doneItem = [[UIBarButtonItem alloc] initWithCustomView: doneButtonView];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarBackgroundImage];
	if (_masterController.selectedObj != nil || _crosswalkController.selectedObj != nil || _favoritesController.selectedObj != nil ){
		self.navigationItem.rightBarButtonItem = _doneItem;
	}else {
		self.navigationItem.rightBarButtonItem = nil;
	}
	
	/*
	 if (_masterController.selectedObj != nil){
	 [_masterController reloadTableData];
	 self.navigationItem.rightBarButtonItem = _doneItem;
	 }
	 if (_crosswalkController.selectedObj != nil){
	 [_crosswalkController reloadTableData];
	 self.navigationItem.rightBarButtonItem = _doneItem;
	 }
	 if (_favoritesController.selectedObj != nil){
	 [_favoritesController reloadTableData];
	 self.navigationItem.rightBarButtonItem = _doneItem;
	 }
	 */
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setNavigationBarBackgroundImage];
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
#pragma mark Actions

- (void)showPatientInfo:(id)sender {
    // TODO
}

- (void)cancelSelectIcd:(id)sender {
	//if(self.isShowingCPTs){
	//	[Cpt eraseRecentCpts];
	//}
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)doneSelectIcd:(id)sender {
    if (self.isShowingCPTs) {
		/*
        AddCptViewController *originViewController = [[((UINavigationController *)self.parentViewController.parentViewController) viewControllers] objectAtIndex:0];
        //originViewController.shouldBeDismissed = YES;
		NSMutableArray *selectedCptArray=nil;
		
        Cpt *selectedCpt = nil;
        if ([[self.view.subviews lastObject] isEqual:_masterController.view]) {
            selectedCpt = _masterController.selectedObj;
        }
        else if ([[self.view.subviews lastObject] isEqual:_favoritesController.view]) {
            selectedCpt = _favoritesController.selectedObj;
        }
        
		SuperbillCpt *superbillCptObj = [[[SuperbillCpt alloc] initWithPrimaryKey:0] autorelease];
		superbillCptObj.cptCode = selectedCpt.code;
		superbillCptObj.cptShortDescription = selectedCpt.shortDescription;
		superbillCptObj.cptLongDescription = selectedCpt.longDescription;
		
		NSMutableString *textToDisplay = [NSMutableString stringWithString:@""];
		[textToDisplay appendString:selectedCpt.code];
		[textToDisplay appendString:@" • "];
		[textToDisplay appendString:selectedCpt.shortDescription];
		superbillCptObj.textToDisplay = textToDisplay;
		
        [Cpt addRecentCpt: superbillCptObj];
        [self.parentViewController dismissModalViewControllerAnimated:YES];*/
    }
    else {
		//Save the record and dismiss the modal
		EncounterIcd *encounterIcd = [[EncounterIcd alloc] initWithPrimaryKey:0];
		NSMutableArray *selectedIcdArray=nil;
		Icd *selectedIcd = nil;
		if ([[self.view.subviews lastObject] isEqual:_masterController.view]) {
			selectedIcdArray = _masterController.selectedObjArray;
		}
		else if ([[self.view.subviews lastObject] isEqual:_favoritesController.view]) {
			selectedIcdArray = _favoritesController.selectedObjArray;
		}
		else if (self.useCrosswalk && [[self.view.subviews lastObject] isEqual:_crosswalkController.view]) {
			selectedIcdArray = _crosswalkController.selectedObjArray;
		}
		NSArray *uniquearray = [[NSSet setWithArray:selectedIcdArray] allObjects];
		[selectedIcdArray removeAllObjects];
		for(Icd *thisIcd in uniquearray)
			[selectedIcdArray addObject:thisIcd];
		
		NSMutableArray *icdArray = [EncounterIcd getEncounterIcdsForCpt:self.sectionObj.encounterCptId];
		for(int i=0;i<[selectedIcdArray count];i++){
			selectedIcd = [selectedIcdArray objectAtIndex:i];
			encounterIcd.encounterCptId = self.sectionObj.encounterCptId;
			encounterIcd.icdCode = selectedIcd.code;
			if([icdArray count]==0){
				if(i==0)
					encounterIcd.isPrimary = TRUE;
				else 
					encounterIcd.isPrimary = FALSE;
			}
			[EncounterIcd addEncounterIcd:encounterIcd];
		}
        
        
		[Encounter_old updateEncounter:encounterId withStatus:EncounterStatusWIP];

        // The current user has become the author of this revision
        //[self.censusObj setMetadataAuthor:[Metadata defaultAuthor]];
        [self.censusObj setRevisionDirty:YES];
        
		[encounterIcd release];
        
		
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}


/*
 - (void)saveSelectedIcd:(id)selectedIcd {
 //Save the record and dismiss the modal
 EncounterIcd *encounterIcd = [[EncounterIcd alloc] initWithPrimaryKey:0];
 Icd *selectedIcd = nil;
 if ([[self.view.subviews lastObject] isEqual:_masterController.view]) {
 selectedIcd = _masterController.selectedObj;
 }
 else if ([[self.view.subviews lastObject] isEqual:_favoritesController.view]) {
 selectedIcd = _favoritesController.selectedObj;
 }
 else if (self.useCrosswalk && [[self.view.subviews lastObject] isEqual:_crosswalkController.view]) {
 selectedIcd = _crosswalkController.selectedObj;
 }
 
 encounterIcd.encounterCptId = self.sectionObj.encounterCptId;
 encounterIcd.icdCode = selectedIcd.code;
 encounterIcd.isPrimary = self.isPrimary;
 NSInteger newEncounterIcdId = [EncounterIcd addEncounterIcd:encounterIcd];
 [Encounter updateEncounter:encounterId withStatus:EncounterStatusWIP];
 [encounterIcd release];
 }*/

#pragma mark -
#pragma mark ICDListViewDelegate

- (void)didSelectObj:(id)selectedIcd {
    self.navigationItem.rightBarButtonItem = _doneItem;
}

- (void)shouldPresentDetails:(Icd *)selectedIcd {
	//    if (!self.isShowingCPTs) {
	IcdDetailsView *detailsController = [[IcdDetailsView alloc] init];
	detailsController.obj = selectedIcd;
	detailsController.censusObj = self.censusObj;
	//detailsController.patient = self.patient;
	//detailsController.dateOfService = self.dateOfService;
	//detailsController.physicianNpi = self.physicianNpi;
    detailsController.superbillId = self.superbillId;
    if (self.isShowingCPTs) {
        detailsController.previousControllerTitle = NSLocalizedString(@"CPT Entry", @"CPT Entry");
    }
    else {
        detailsController.previousControllerTitle = NSLocalizedString(@"ICD Entry", @"ICD Entry");
    }
	[self.navigationController pushViewController:detailsController animated:YES];
	[detailsController release];
	//    }
}

#pragma mark -
#pragma mark PatientListViewDelegate

- (void)patientViewClicked:(Patient_old *)patient {
    RoundViewController *patientView = [[RoundViewController alloc] init];
    //patientView.census = [[Census getCensusObject:self.censusId] objectAtIndex:0];
	PhysicianPref *physicianPref = [PhysicianPref getPhysicianPrefs:self.censusObj.physicianNpi];
	patientView.physicianPref = physicianPref;
    patientView.census = self.censusObj;
    patientView.currentViewMode = QliqModelViewModeView;
	if(self.isShowingCPTs)
		patientView.previousControllerTitle = NSLocalizedString(@"CPT Entry", @"CPT Entry");
	else
		patientView.previousControllerTitle = NSLocalizedString(@"ICD Entry", @"ICD Entry");
    [self.navigationController pushViewController:patientView animated:YES];
    [patientView release];
}

#pragma mark -
#pragma mark Private

- (void)selectTab:(id)sender {
	
    mainTabView.favoritesButton.selected = NO;
    mainTabView.allButton.selected = NO;
    mainTabView.favoritesLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
    mainTabView.allLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
    if (self.useCrosswalk) {
        mainTabView.crosswalkButton.selected = NO;
        mainTabView.crosswalkLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
    }
	
    self.navigationItem.rightBarButtonItem = nil;
	
    UIButton *btn = sender;
    switch (btn.tag) {
        case 1:
        {
            mainTabView.favoritesButton.selected = YES;
            mainTabView.favoritesLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
            if (_favoritesController.selectedObj != nil) {
                self.navigationItem.rightBarButtonItem = _doneItem;
            }
			if (self.isShowingCPTs) {
				[favList release];
				favList = [[Cpt getFavoriteCptsToDisplay:self.superbillId] retain];
			}
			else {
				[favList release];
				favList = [[Icd getFavoriteIcdsToDisplay:self.censusObj.physicianNpi] retain];
			}
			_favoritesController.listOfIcdCodes=favList;
            [self.view bringSubviewToFront:_favoritesController.view];
			[_favoritesController reloadTableData];
        }
            break;
			
        case 2:
        {
			if (self.useCrosswalk) {
				[crosswalkList release];
				crosswalkList = [[Icd getCrosswalkIcdsToDisplay:self.sectionObj.encounterCptId] retain];
			}
            mainTabView.crosswalkButton.selected = YES;
            mainTabView.crosswalkLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
            if (_crosswalkController.selectedObj != nil) {
                self.navigationItem.rightBarButtonItem = _doneItem;
            }
			_crosswalkController.listOfIcdCodes=crosswalkList;
            [self.view bringSubviewToFront:_crosswalkController.view];
			[_crosswalkController reloadTableData];
        }
            break;
			
        case 3:
        {
            mainTabView.allButton.selected = YES;
            mainTabView.allLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
            if (_masterController.selectedObj != nil) {
                self.navigationItem.rightBarButtonItem = _doneItem;
            }
            [self.view bringSubviewToFront:_masterController.view];
        }
            break;
    }
}


@end
