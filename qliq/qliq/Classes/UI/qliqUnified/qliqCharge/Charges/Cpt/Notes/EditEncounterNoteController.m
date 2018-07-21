#import "EditEncounterNoteController.h"
//#import "NoteType.h"
#import "EncounterNote.h"
#import "Encounter_old.h"
#import "Patient_old.h"

@implementation EditEncounterNoteController

@synthesize censusObj;
//@synthesize patient;
@synthesize dateOfService=_dateOfService;
@synthesize noteType;
@synthesize note;

- (id) init
{
	if ((self = [super init]))
	{
        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver: self 
                   selector: @selector(keyboradWillBeShown:) 
                       name: @"UIKeyboardWillShowNotification" 
                     object: nil];
        
        [center addObserver: self 
                   selector: @selector(keyboradWasShown:) 
                       name: @"UIKeyboardDidShowNotification" 
                     object: nil];
        
        
        [center addObserver: self 
                   selector: @selector(keyboradWillBeHidden:) 
                       name: @"UIKeyboardWillHideNotification" 
                     object: nil];  
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(removeNotificationObserver) 
                                                     name:@"RemoveNotifications" object:nil];
	}
    
	return self;
} // [EditEncounterNoteController init]

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void) viewDidLoad
{
    [super viewDidLoad];
    
    //self.navigationItem.rightBarButtonItem = [self rightItemWithTitle: NSLocalizedString(@"Save", @"Note") 
    //                                                      buttonImage: [UIImage imageNamed: @"btn-done"]
    //                                                     buttonAction: @selector(saveNote:)];
    
   
	UIButton* doneButtonView = [UIButton buttonWithType: UIButtonTypeCustom];
	UIImage* doneButtonImage = [[UIImage imageNamed: @"bg-cancel-btn.png"] stretchableImageWithLeftCapWidth: 17 topCapHeight: 0];
	[doneButtonView setBackgroundImage: doneButtonImage
							  forState: UIControlStateNormal];
	[doneButtonView setTitle: @"Done" forState: UIControlStateNormal];
	doneButtonView.titleLabel.font = [UIFont boldSystemFontOfSize: 12.0f];
	doneButtonView.frame = CGRectMake(0.0f, 0.0f, 80.0f, 42.0f);
	[doneButtonView addTarget: self 
					   action: @selector(saveNote:)
			 forControlEvents: UIControlEventTouchUpInside];
	UIBarButtonItem *_doneItem = [[[UIBarButtonItem alloc] initWithCustomView: doneButtonView] autorelease];
	
	self.navigationItem.rightBarButtonItem = _doneItem;
	
	patient = [Patient_old getPatientToDisplay:self.censusObj.patientId];
	if(patient){
		patientView = [self patientHeader:self.censusObj
							dateOfService:_dateOfService
								 delegate:self];
		[patientView setState:UIControlStateDisabled];	
		[self.view addSubview:patientView];
    }

	patient = [Patient_old getPatientToDisplay:self.censusObj.patientId];
	if(patient){
		patientView = [self patientHeader:self.censusObj
							dateOfService:self.censusObj.dateOfService
								 delegate:self];
		[patientView setState:UIControlStateDisabled];	
		[self.view addSubview:patientView];
    }
	
    UIView* patientHeader = [self patientHeader: self.censusObj
                                  dateOfService: self.dateOfService 
                                       delegate: self];
    [self.view addSubview: patientHeader];
	
    // Top info pane
    topInfoPane = [[[UIView alloc] initWithFrame: CGRectMake(0.0f, CGRectGetMaxY(patientView.frame), 
                                                             CGRectGetWidth(self.view.frame), 29.0f)] autorelease];
    topInfoPane.backgroundColor = [UIColor colorWithRed: 0.25f green: 0.25f blue: 0.25f alpha: 1.0];
	
    // Note type label
    noteTypeLabel = [[[UILabel alloc] initWithFrame: CGRectMake(7.0f, 0.0, CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(topInfoPane.frame))] autorelease];
    noteTypeLabel.text = noteType.description;
    noteTypeLabel.backgroundColor = [UIColor clearColor];
    noteTypeLabel.textColor = [UIColor whiteColor];
    noteTypeLabel.font = [UIFont boldSystemFontOfSize: 12];
    
    // Persistant note button
    persistNoteButton = [UIButton buttonWithType: UIButtonTypeCustom];
    [persistNoteButton setBackgroundImage: [UIImage imageNamed: @"btn-persist-off.png"] forState: UIControlStateNormal];
    [persistNoteButton setBackgroundImage: [UIImage imageNamed: @"btn-persist-on.png"] forState: UIControlStateSelected];
    [persistNoteButton addTarget: self
                          action: @selector(persistNotePressed:)
                forControlEvents: UIControlEventTouchUpInside];
    
    CGSize buttonSize = persistNoteButton.currentBackgroundImage.size;
    persistNoteButton.frame = CGRectMake(CGRectGetWidth(topInfoPane.frame) - 7.0 - buttonSize.width, (int)((CGRectGetHeight(topInfoPane.frame) - buttonSize.height) / 2),
                                         buttonSize.width, buttonSize.height);
    
    // Persist note label
    persistNoteLabel = [[[UILabel alloc] initWithFrame: CGRectMake(CGRectGetMinX(persistNoteButton.frame) - CGRectGetWidth(self.view.frame) / 2 - 5, 0.0, 
																   CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(topInfoPane.frame))] autorelease];
    persistNoteLabel.text = NSLocalizedString(@"Persist Note", "Persist note");
    persistNoteLabel.backgroundColor = [UIColor clearColor];
    persistNoteLabel.textColor = [UIColor whiteColor];
    persistNoteLabel.textAlignment = UITextAlignmentRight;
    persistNoteLabel.font = [UIFont boldSystemFontOfSize: 12];
    
	
    [topInfoPane addSubview: noteTypeLabel];
    [topInfoPane addSubview: persistNoteButton];
    [topInfoPane addSubview: persistNoteLabel];
    [self.view addSubview: topInfoPane];    
	
    
    // Note text view
    noteTextView = [[[UITextView alloc] initWithFrame: CGRectMake(0.0f, CGRectGetMaxY(topInfoPane.frame),
																  CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetMaxY(topInfoPane.frame))] autorelease];
    noteTextView.font = [UIFont systemFontOfSize: 16];
    noteTextView.text = note.textNote;
	[self.view addSubview: noteTextView];
    
    
} // [EditEncounterNoteController viewDidLoad]


- (void) viewWillAppear: (BOOL) animated
{
    [noteTextView becomeFirstResponder];
} // [EditEncounterNoteController viewWillAppear:]

- (void) dealloc
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self];
    
    [note release];
    
    [super dealloc];
} // [EditEncounterNoteController dealloc]


#pragma mark -
#pragma mark -- PatientHeaderViewDelegate --

- (void) patientViewClicked: (Patient_old*) patient
{
    DDLogInfo(@"patient view clicked");    
} // [EncounterNotesViewController patientViewClicked:]


#pragma mark -
#pragma mark -- Keyborad notifications --

- (void) keyboradWillBeShown: (NSNotification*) notification
{
    if (notification != nil)
	{
		NSDictionary* userInfo = [notification userInfo];
        
        NSValue* value = [userInfo objectForKey: UIKeyboardFrameEndUserInfoKey];
        CGRect endKeyboardRect = [value CGRectValue];
        
        NSNumber* animationValue = [userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey];
        float animationDuration = [animationValue floatValue];
        
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationDuration: animationDuration];
        
        CGRect noteTextFrame = noteTextView.frame;
        CGRect noteTextFrameGlobal = [self.view convertRect: noteTextFrame toView: self.view.window];
        noteTextFrame.size.height = CGRectGetMinY(endKeyboardRect) - CGRectGetMinY(noteTextFrameGlobal);
        noteTextView.frame = noteTextFrame;
        
        [UIView commitAnimations];
    }
} // [EditEncounterNoteController keyboradWillBeShown:]


- (void) keyboradWillBeHidden: (NSNotification*) notification
{
    if (notification != nil)
	{
		NSDictionary* userInfo = [notification userInfo];
        
        NSNumber* animationValue = [userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey];
        float animationDuration = [animationValue floatValue];
        
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationDuration: animationDuration];
        
        CGRect noteTextFrame = noteTextView.frame;
        noteTextFrame.size.height = CGRectGetHeight(self.view.frame) - CGRectGetMaxY(topInfoPane.frame);
        noteTextView.frame = noteTextFrame;
        
        [UIView commitAnimations];
    }
} // [EditEncounterNoteController keyboradWillBeHidden:]


- (void) keyboradWasShown: (NSNotification*) notification
{
} // [EditEncounterNoteController keyboradWasShown:]



#pragma mark -
#pragma mark -- UITextFieldDelegate --


- (void) textFieldDidBeginEditing: (UITextField*) textField
{
} // [EncounterNotesViewController textFieldDidBeginEditing:]


- (void) textFieldDidEndEditing: (UITextField*) textField
{
	//    UITableViewCell* cell = [noteTypesTable cellForRowAtIndexPath: [NSIndexPath indexPathForRow: [noteTypesArray count] 
	//                                                                                      inSection: 0]];
	//    cell.textLabel.hidden = NO;
	//    
	//    [textField removeFromSuperview];    
} // [EncounterNotesViewController textFieldDidEndEditing:]


//- (BOOL) textFieldShouldReturn: (UITextField*) textField
//{
//
////    
////    NoteType* newNoteType = [[NoteType alloc] initWithPrimaryKey: ++biggestNoteTypeId];
////    newNoteType.description = textField.text;
////    [NoteType addNoteType: newNoteType];
////    
////    [self updateData];
////    
////    //    [noteTypesTable insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow: [noteTypesArray count] inSection: 0]]
////    //                          withRowAnimation: UITableViewRowAnimationTop];
////    [noteTypesTable reloadData];
////    
////    return YES;
//} // [EncounterNotesViewController textFieldShouldReturn:]



#pragma mark -
#pragma mark -- Functionality --

- (void) setNote: (EncounterNote*) aNote
{
    [note autorelease];
    note = [aNote retain];
    noteTextView.text = note.textNote;
} // [EditEncounterNoteController setNote:]

- (void) persistNotePressed: (id) sender
{
    persistNoteButton.selected = !persistNoteButton.selected;
	[Encounter_old updateEncounter:note.encounterId withStatus:EncounterStatusWIP];

} // [EditEncounterNoteController persistNotePressed:]

- (void) saveNote: (id) sender
{
	
	if([noteTextView.text length] > 0){
		if (note.encounterNoteId == 0)
		{
			note.textNote = noteTextView.text;
			[EncounterNote addEncounterNote: note];
		}
		else
		{
			note.textNote = noteTextView.text;
			[EncounterNote updateEncounterNote: note];
		}
		[Encounter_old updateEncounter:note.encounterId withStatus:EncounterStatusWIP];
		[self.navigationController popViewControllerAnimated: YES];
	}else {
		[self showAlertWithTitle:NSLocalizedString(@"Empty notes ", @"Empty notes ") 
						 message:NSLocalizedString(@"Please enter the notes before saving", @"Please enter the notes before saving")];
	}



} // [EditEncounterNoteController persistNotePressed:]

- (void)showAlertWithTitle:(NSString *)aTitle message:(NSString *)aMessage {
	UIAlertView *alert=[[UIAlertView alloc]initWithTitle:aTitle
												 message:aMessage 
												delegate:self 
									   cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
									   otherButtonTitles:nil];
	[alert show];
	[alert release];
}


@end
