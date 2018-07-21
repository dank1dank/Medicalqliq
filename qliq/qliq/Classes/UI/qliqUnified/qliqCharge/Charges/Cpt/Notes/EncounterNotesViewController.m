#import "EncounterNotesViewController.h"
#import "LightGreyGlassGradientView.h"
#import "StretchableButton.h"
#import "EncounterNote.h"
#import "Encounter_old.h"
#import "PatientTableViewCell.h"
#import "EditEncounterNoteController.h"
#import "ConversationListViewController.h"

@interface EncounterNotesViewController(Private)

- (void) updateData;

- (void) addNote: (id) sender;
- (void) showChat: (id) sender;
- (void) toggleEdit: (id) sender;
- (void) clickFinish: (id) sender;

- (void) keyboradWillBeShown: (NSNotification*) notification;
- (void) keyboradWillBeHidden: (NSNotification*) notification;
- (void) keyboradWasShown: (NSNotification*) notification;
@end


static const NSUInteger MaxNumberOfRowsToExpand = 8;

@implementation EncounterNotesViewController

/*
@synthesize patient;
@synthesize censusId;
@synthesize apptId;
@synthesize attendingPhysicianId;
*/
@synthesize censusObj;
@synthesize dateOfService=_dateOfService;

- (id) init
{
	if ((self = [super init]))
	{
//		self.title = NSLocalizedString(@"Notes", "Notes view controller title");
        
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave
//                                                                                               target: self 
//                                                                                               action: @selector(saveGoal)];        
	}
	
    
	return self;
} // [EncounterNotesViewController init]



- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
	Patient_old *patient = [Patient_old getPatientToDisplay:self.censusObj.patientId];
	if(patient){
		patientView = [self patientHeader:self.censusObj
							 dateOfService:_dateOfService
								  delegate:self];
		[patientView setState:UIControlStateDisabled];	
		[self.view addSubview:patientView];
    }
	
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle: NSLocalizedString(@"Notes", @"Note") 
                                                          buttonImage: [UIImage imageNamed:@"btn-add"]
														buttonAction: @selector(addNote:)];
    /*UIView* patientHeader = [self patientHeader: self.patient
                                  dateOfService: self.dateOfService 
                                       delegate: self];
    [self.view addSubview: patientHeader];
	 */
    buttonView = [[UIView alloc] initWithFrame: CGRectMake(0, 374, 320, 42)];
    LightGreyGlassGradientView *bgView = [[LightGreyGlassGradientView alloc] initWithFrame:buttonView.bounds];
    [buttonView addSubview: bgView];
    [bgView release];
        
    self.chatButton = [StretchableButton buttonWithType: UIButtonTypeCustom];
    self.chatButton.btnType = StretchableButton25;
    self.chatButton.frame = CGRectMake(16, 0, 65, 42);
    [self.chatButton setTitle: NSLocalizedString(@"Chat", @"Chat") forState: UIControlStateNormal];
    self.chatButton.titleLabel.font = [UIFont boldSystemFontOfSize: 12.f];
    [self.chatButton addTarget: self action: @selector(showChat:) forControlEvents: UIControlEventTouchUpInside];
    [buttonView addSubview: self.chatButton];
    
	/*
    editButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
    editButton.btnType = StretchableButton25;
    editButton.frame = CGRectMake(175, 0, 65, 42);
    [editButton setTitle:NSLocalizedString(@"Edit", @"Edit") forState: UIControlStateNormal];
    [editButton setTitle:NSLocalizedString(@"Done", @"Done") forState: UIControlStateSelected];
    editButton.titleLabel.font = [UIFont boldSystemFontOfSize: 12.f];
    [editButton addTarget: self action: @selector(toggleEdit:) forControlEvents: UIControlEventTouchUpInside];
    [buttonView addSubview: editButton];
    
    finishButton = [StretchableButton buttonWithType:UIButtonTypeCustom];
    finishButton.btnType = StretchableButton25;
    finishButton.frame = CGRectMake(245, 0, 65, 42);
    [finishButton setTitle:NSLocalizedString(@"Finish", @"Finish") forState:UIControlStateNormal];
    finishButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
    [finishButton addTarget:self action:@selector(clickFinish:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView addSubview: finishButton];

    [self.view addSubview: buttonView];
    */

	notesTable = [[UITableView alloc] initWithFrame: CGRectMake(0,43,320,373) style:0];
	notesTable.editing = NO;
	notesTable.delegate = self;
	notesTable.dataSource = self;
	notesTable.separatorStyle = 1;
	notesTable.rowHeight = 40;
	notesTable.clipsToBounds = YES;
    notesTable.backgroundColor = [UIColor colorWithWhite: 0.2039f alpha: 1.0f];
    notesTable.separatorColor = [UIColor colorWithWhite: 0.2039f alpha: 1.0f];
	[self.view addSubview: notesTable];
    
    
    noteTypesTable = [[UITableView alloc] initWithFrame: CGRectMake(0,43,320,373) style:0];
	noteTypesTable.editing = NO;
	noteTypesTable.delegate = self;
	noteTypesTable.dataSource = self;
	noteTypesTable.separatorStyle = 1;
	noteTypesTable.rowHeight = 40;
	noteTypesTable.clipsToBounds = YES;
    noteTypesTable.backgroundColor = [UIColor colorWithWhite: 0.2039f alpha: 1.0f];
    noteTypesTable.separatorColor = [UIColor colorWithWhite: 0.2039f alpha: 1.0f];
    noteTypesTable.hidden = YES;
    

    // No notes label
    UILabel* noNotesLabel = [[[UILabel alloc] initWithFrame: CGRectMake(7.0f, CGRectGetMinY(notesTable.frame) + 7.0f, CGRectGetWidth(self.view.frame) - 14.0, 0)] autorelease];
    noNotesLabel.text = NSLocalizedString(@"No notes for this patient on this day.\nTap \"+\" above to create one", "no notes text");
    noNotesLabel.textColor = [UIColor colorWithRed: 0.42f green: 0.42f blue: 0.42f alpha: 1.0f];
    noNotesLabel.backgroundColor = [UIColor clearColor];
    noNotesLabel.font = [UIFont systemFontOfSize: 14];
    noNotesLabel.numberOfLines = 0;
    [noNotesLabel sizeToFit];
    [self.view addSubview: noNotesLabel];
    [self.view sendSubviewToBack: noNotesLabel];
    
    [self updateData];
} // [EncounterNotesViewController viewDidLoad]


- (void) viewWillAppear: (BOOL) animated
{
    [super viewWillAppear:animated];
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

    [self updateData];
    [notesTable reloadData];

    
    if ([notesToCategoriesMap count] == 0)
    {
        notesTable.hidden = YES;
    }
    else
    {
        if (notesTable.hidden)
        {
            [noteTypesTable removeFromSuperview];
            noteTypesTable.hidden = YES;
            
            [self.view addSubview: notesTable];
            notesTable.hidden = NO;
        }
    }
    
    editButton.hidden = !notesTable.hidden;
} // [EncounterNotesViewController viewWillAppear:]


- (void) viewWillDisappear: (BOOL) animated
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self];
} // [EncounterNotesViewController viewWillDisappear:]

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void) dealloc
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self];
    
    [super dealloc];
} // [EncounterNotesViewController dealloc]


#pragma mark -
#pragma mark -- UITableViewDataSource --

- (CGFloat)     tableView: (UITableView*) tableView
  heightForRowAtIndexPath: (NSIndexPath*) indexPath
{
    // Main table
    if (tableView == notesTable)
    {
        NoteType* noteType = [noteTypesArray objectAtIndex: indexPath.section];
        NSArray* notesArray = [notesToCategoriesMap objectForKey: [NSNumber numberWithInt: noteType.noteTypeId]];
        
        // usual cell
        if (indexPath.row < notesArray.count)
        {
            EncounterNote* note = [notesArray objectAtIndex: indexPath.row];
            
            UILabel* testLabel = [[[UILabel alloc] initWithFrame: CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.frame) - 30, 0.0f)] autorelease];
            testLabel.font = [UIFont systemFontOfSize: 14];
            testLabel.numberOfLines = 0;
            testLabel.text = note.textNote;
            [testLabel sizeToFit];
            
            if (CGRectGetHeight(testLabel.frame) < 40)
                return 40;
            else 
                return CGRectGetHeight(testLabel.frame);
        }
        else
        {
            return 40;
        }

    }
    // "Add note" table
    else if (tableView == noteTypesTable)
    {
        return 40;
    }
    return 0;
    
} // [EncounterNotesViewController numberOfSectionsInTableView:]


- (NSInteger) numberOfSectionsInTableView: (UITableView*) tableView
{
    // Main table
    if (tableView == notesTable)
    {
        return [noteTypesArray count];
    }
    // "Add note" table
    else if (tableView == noteTypesTable)
    {
        return 1;
    }
    return 0;
} // [EncounterNotesViewController numberOfSectionsInTableView:]


- (NSInteger) tableView: (UITableView*) tableView
  numberOfRowsInSection: (NSInteger) section 
{
    // Main table
    if (tableView == notesTable)
    {
        if (section == expandedSection)
        {
            int result = 0;
            
            // Get the number of notes for this section
            NoteType* noteType = [noteTypesArray objectAtIndex: section];
            NSArray* notesArray = [notesToCategoriesMap objectForKey: [NSNumber numberWithInt: noteType.noteTypeId]];
            
            // One more item for add new note
            result = [notesArray count] + 1;
            
            if (result > MaxNumberOfRowsToExpand && expandingInProgress)
                result = MaxNumberOfRowsToExpand;

            return result;

        }
        else
        {
            return 0;
        }

    }
    // "Add note" table
    else
    {
        return [fullNoteTypesArray count] + 1;
    }   
} // [EncounterNotesViewController tableView: numberOfRowsInSection:]
    

- (UITableViewCell*)tableView: (UITableView*) tableView
        cellForRowAtIndexPath: (NSIndexPath*) indexPath 
{
    PatientTableViewCell* cell;
    NSString* CellIdentifier = @"NotesCell";
    NSString* AddCellIdentifier = @"AddNewNoteCell";
    
    cell = (PatientTableViewCell*)[tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) 
    {
        cell = [[[PatientTableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier] autorelease];
    }

    cell.backgroundView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"bg-cell"]];
    cell.contentView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"bg-cell"]];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    // Main table
    if (tableView == notesTable)
    {
        NoteType* noteType = [noteTypesArray objectAtIndex: indexPath.section];
        NSArray* notesArray = [notesToCategoriesMap objectForKey: [NSNumber numberWithInt: noteType.noteTypeId]];

        // usual cells
        if (indexPath.row < [notesArray count])
        {
            EncounterNote* note = [notesArray objectAtIndex: indexPath.row];   

            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = note.textNote;
        }
        // add new note cell
        else
        {
            cell = (PatientTableViewCell*)[tableView dequeueReusableCellWithIdentifier: AddCellIdentifier];
            
            if (cell == nil) 
            {
                cell = [[[PatientTableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: AddCellIdentifier] autorelease];
            }
            
            cell.backgroundView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"bg-cell"]];
            cell.contentView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"bg-cell"]];
            cell.textLabel.backgroundColor = [UIColor clearColor];
            
            cell.textLabel.text = [NSString stringWithFormat: @"Add new %@", noteType.description];
            cell.textLabel.textAlignment = UITextAlignmentRight;
            cell.accessoryView = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"btn-add-blue.png"]] autorelease];
        }
        
        cell.textLabel.font = [UIFont systemFontOfSize: 14];
    }
    // "Add note" table
    else
    {
        // Existing note types
        if (indexPath.row < [fullNoteTypesArray count])
        {
            NoteType* noteType = [fullNoteTypesArray objectAtIndex: indexPath.row];
            cell.textLabel.text = noteType.description;
        }
        // The new one to create
        else
        {
            cell.textLabel.text = NSLocalizedString(@"Create New Note Type", "Title of the cell to add a new note");
        }
        cell.textLabel.font = [UIFont boldSystemFontOfSize: 14];
    }
    return cell;
} // [EncounterNotesViewController tableView: cellForRowAtIndexPath:]


- (UIView*)  tableView: (UITableView*) tableView
viewForHeaderInSection: (NSInteger) section 
{
    // Main table
    if (tableView == notesTable)
    {
        
        NoteType* noteType = [noteTypesArray objectAtIndex: section];
        
        SectionHeaderView* headerView = [[[SectionHeaderView alloc] initWithFrame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, HEADER_HEIGHT) 
                                                                            title: noteType.description
                                                                          section: section 
                                                                         delegate: self] autorelease];
        headerView.disclosureButton.selected = (expandedSection == section);
        
        headerView.tag = 500 + section;
        
        return headerView;
    }
    // "Add note" table
    else 
    {
        return nil;
    }
} // [EncounterNotesViewController tableView: viewForHeaderInSection:]


- (CGFloat)     tableView: (UITableView*) tableView
 heightForHeaderInSection: (NSInteger) section
{
    // Main table
    if (tableView == notesTable)
    {
        return HEADER_HEIGHT;
    }
    // "Add note" table
    else
    {
        return 0;
    }        
    
} // [EncounterNotesViewController tableView: heightForHeaderInSection:]


#pragma mark -
#pragma mark -- UITableViewDelegate --
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCellEditingStyle) tableView: (UITableView*) tableView
            editingStyleForRowAtIndexPath: (NSIndexPath*) indexPath
{
    UITableViewCellEditingStyle result = UITableViewCellEditingStyleDelete;
    
    // Main table
    if (tableView == notesTable)
    {
        NoteType* noteType = [noteTypesArray objectAtIndex: indexPath.section];
        NSArray* notesArray = [notesToCategoriesMap objectForKey: [NSNumber numberWithInt: noteType.noteTypeId]];
        
        // Existing note types
        if (indexPath.row < [notesArray count])
        {
            result = UITableViewCellEditingStyleDelete;
        }
        else
        {
            result = UITableViewCellEditingStyleNone;            
        }
    }
    // "Add note" table
    else
    {
        // Existing note types
        if (indexPath.row < [fullNoteTypesArray count])
        {
            result = UITableViewCellEditingStyleDelete;
        }
        else
        {
            result = UITableViewCellEditingStyleNone;            
        }
    }
    return result;
} // [EncounterNotesViewController tableView: editingStyleForRowAtIndexPath:]


- (void)			  tableView: (UITableView*) tableView
        didSelectRowAtIndexPath: (NSIndexPath*) indexPath
{
    // Main table
    if (tableView == notesTable)
    {
        [tableView deselectRowAtIndexPath: indexPath animated: YES];

        NoteType* noteType = [noteTypesArray objectAtIndex: indexPath.section];
        NSArray* notesArray = [notesToCategoriesMap objectForKey: [NSNumber numberWithInt: noteType.noteTypeId]];
        
        EditEncounterNoteController* editNoteController = [[EditEncounterNoteController alloc] init];
        editNoteController.previousControllerTitle = NSLocalizedString(@"Notes", "Notes");
		editNoteController.censusObj = self.censusObj;
        editNoteController.noteType = noteType;
        
        EncounterNote* note;
        
        // usual cells
        if (indexPath.row < [notesArray count])
        {
            note = [notesArray objectAtIndex: indexPath.row];   
        }
        // add new note cell
        else
        {
            note = [[[EncounterNote alloc] initWithPrimaryKey: 0] autorelease];
            note.typeId = noteType.noteTypeId;
            note.encounterId = encounterCensusId;            
        }

        editNoteController.note = note;
        [self.navigationController pushViewController: editNoteController animated: YES];
        [editNoteController release];
    }
    // "Add note" table
    else
    {
        [tableView deselectRowAtIndexPath: indexPath animated: NO];
        
        // The last row selected
        if (indexPath.row == [fullNoteTypesArray count])
        {
            UITableViewCell* cell = [tableView cellForRowAtIndexPath: indexPath];
            cell.textLabel.hidden = YES;

            UITextField* textField = [[[UITextField alloc] initWithFrame: CGRectInset(cell.contentView.frame, 10.0f, 10.0f)] autorelease];
            textField.returnKeyType = UIReturnKeyDone;
            textField.delegate = self;
            
            [cell.contentView addSubview: textField];
            [textField becomeFirstResponder];
        }
        else
        {
            EditEncounterNoteController* editNoteController = [[EditEncounterNoteController alloc] init];
            editNoteController.previousControllerTitle = NSLocalizedString(@"Notes", "Notes");
            editNoteController.censusObj = self.censusObj;
			editNoteController.dateOfService = self.dateOfService;
            NoteType* noteType = [fullNoteTypesArray objectAtIndex: indexPath.row];
            editNoteController.noteType = noteType;
            
            EncounterNote* newNoteToSave = [[[EncounterNote alloc] initWithPrimaryKey: 0] autorelease];
            newNoteToSave.typeId = noteType.noteTypeId;
            newNoteToSave.encounterId = encounterCensusId;
            
            editNoteController.note = newNoteToSave;
            
            [self.navigationController pushViewController: editNoteController animated: YES];
            [editNoteController release];
        }
    }    
} // [HabitInfoViewController tableView: didSelectRowAtIndexPath:]


- (void) tableView: (UITableView*) tableView
commitEditingStyle: (UITableViewCellEditingStyle) editingStyle
 forRowAtIndexPath: (NSIndexPath*) indexPath
{
    // Delete editing
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Main table
        if (tableView == notesTable)
        {
            NoteType* noteType = [noteTypesArray objectAtIndex: indexPath.section];
            NSArray* notesArray = [notesToCategoriesMap objectForKey: [NSNumber numberWithInt: noteType.noteTypeId]];            
            EncounterNote* note= [notesArray objectAtIndex: indexPath.row];
            
            [EncounterNote deleteEncounterNote: note.encounterNoteId];
			[Encounter_old updateEncounter:note.encounterId withStatus:EncounterStatusWIP];

        }
        // "Add note" table
        else
        {
            NoteType* noteType = [fullNoteTypesArray objectAtIndex: indexPath.row];
            [NoteType deleteNoteType: noteType.noteTypeId];
        }
        
        [self updateData];
        [tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                         withRowAnimation: UITableViewRowAnimationTop];

    }    
} // [HabitInfoViewController tableView: commitEditingStyle: forRowAtIndexPath:]



#pragma mark -
#pragma mark -- UITextFieldDelegate --


- (void) textFieldDidBeginEditing: (UITextField*) textField
{
} // [EncounterNotesViewController textFieldDidBeginEditing:]


- (void) textFieldDidEndEditing: (UITextField*) textField
{
    UITableViewCell* cell = [noteTypesTable cellForRowAtIndexPath: [NSIndexPath indexPathForRow: [fullNoteTypesArray count] 
                                                                                      inSection: 0]];
    cell.textLabel.hidden = NO;
    
    [textField removeFromSuperview];    
} // [EncounterNotesViewController textFieldDidEndEditing:]


- (BOOL) textFieldShouldReturn: (UITextField*) textField
{
    [textField resignFirstResponder];
    
    NoteType* newNoteType = [[NoteType alloc] initWithPrimaryKey: 0];
    newNoteType.description = textField.text;
    newNoteType.noteTypeId = ++biggestNoteTypeId;
    [NoteType addNoteType: newNoteType];
	[newNoteType release];
    
    [self updateData];

    [noteTypesTable reloadData];

    return YES;
} // [EncounterNotesViewController textFieldShouldReturn:]


#pragma mark -
#pragma mark -- UIScrollViewDelegate --

- (void) scrollViewDidScroll: (UIScrollView*) scrollView
{
    if (expandingInProgress)
    {
        expandingInProgress = NO;
        [notesTable reloadData];
    }
} // [EncounterNotesViewController scrollViewDidScroll:]



#pragma mark -
#pragma mark -- PatientHeaderViewDelegate --

- (void) patientViewClicked: (Patient_old*) patient
{
    DDLogInfo(@"patient view clicked");    
} // [EncounterNotesViewController patientViewClicked:]

#pragma mark -
#pragma mark -- Section header delegate --

- (void) sectionHeaderView: (SectionHeaderView*) sectionHeaderView
             sectionOpened: (NSInteger) sectionOpened 
{
    // Define rows to delete
    NSInteger countOfRowsToDelete = 0;
    NSMutableArray* indexPathsToDelete;
    if (expandedSection != -1)
    {
        countOfRowsToDelete = [notesTable numberOfRowsInSection: expandedSection];
        indexPathsToDelete = [NSMutableArray arrayWithCapacity: 10];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) 
        {
            [indexPathsToDelete addObject: [NSIndexPath indexPathForRow: i inSection: expandedSection]];
        }
        
        SectionHeaderView* headerView = (SectionHeaderView*)[notesTable viewWithTag: 500 + expandedSection];
        headerView.disclosureButton.selected = NO;
    }
    
    expandedSection = sectionOpened;

    // Define rows to add
    NSInteger countOfRowsToInsert = 0;
    NSMutableArray* indexPathsToInsert;

    NoteType* noteType = [noteTypesArray objectAtIndex: expandedSection];
    NSArray* notesArray = [notesToCategoriesMap objectForKey: [NSNumber numberWithInt: noteType.noteTypeId]];    

    // One more row for add new note
    countOfRowsToInsert = [notesArray count] + 1;
    
    if (countOfRowsToInsert > MaxNumberOfRowsToExpand)
    {
        countOfRowsToInsert = MaxNumberOfRowsToExpand;
        expandingInProgress = YES;
    }
    
    indexPathsToInsert = [NSMutableArray arrayWithCapacity: 10];
    for (NSInteger i = 0; i < countOfRowsToInsert; i++)
    {
        [indexPathsToInsert addObject: [NSIndexPath indexPathForRow: i inSection: expandedSection]];
    }
    
    [notesTable beginUpdates];
    [notesTable insertRowsAtIndexPaths: indexPathsToInsert
                      withRowAnimation: UITableViewRowAnimationFade];

    if (countOfRowsToDelete)
    {
        [notesTable deleteRowsAtIndexPaths: indexPathsToDelete
                          withRowAnimation: UITableViewRowAnimationFade];
    }
    [notesTable endUpdates];
}


- (void) sectionHeaderView: (SectionHeaderView*) sectionHeaderView
             sectionClosed: (NSInteger) sectionClosed 
{
    expandedSection = -1;

    NSInteger countOfRowsToDelete = [notesTable numberOfRowsInSection: sectionClosed];

    
    if (countOfRowsToDelete > 0)
    {
        NSMutableArray* indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) 
        {
            [indexPathsToDelete addObject: [NSIndexPath indexPathForRow: i
                                                              inSection: sectionClosed]];
        }
        [notesTable beginUpdates];
        [notesTable deleteRowsAtIndexPaths: indexPathsToDelete
                          withRowAnimation: UITableViewRowAnimationTop];
        [notesTable endUpdates];
        [indexPathsToDelete release];
    }
}


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
        
        CGRect notesTypeFrame = noteTypesTable.frame;
        CGRect notesTypeFrameGlobal = [self.view convertRect: notesTypeFrame toView: self.view.window];
        notesTypeFrame.size.height = CGRectGetMinY(endKeyboardRect) - CGRectGetMinY(notesTypeFrameGlobal);
        noteTypesTable.frame = notesTypeFrame;
        
        [UIView commitAnimations];
    }
} // [EncounterNotesViewController keyboradWillBeShown:]


- (void) keyboradWillBeHidden: (NSNotification*) notification
{
    if (notification != nil)
	{
		NSDictionary* userInfo = [notification userInfo];
        
        NSNumber* animationValue = [userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey];
        float animationDuration = [animationValue floatValue];
        
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationDuration: animationDuration];
        
        CGRect notesTypeFrame = noteTypesTable.frame;
        notesTypeFrame.size.height = CGRectGetMinY(buttonView.frame) - CGRectGetMinY(noteTypesTable.frame);
        noteTypesTable.frame = notesTypeFrame;
        
        [UIView commitAnimations];
    }
} // [EncounterNotesViewController keyboradWillBeHidden:]


- (void) keyboradWasShown: (NSNotification*) notification
{
    [noteTypesTable scrollToRowAtIndexPath: [NSIndexPath indexPathForRow: [fullNoteTypesArray count] inSection: 0]
                          atScrollPosition: UITableViewScrollPositionBottom 
                                  animated: YES];
} // [EncounterNotesViewController keyboradWasShown:]

#pragma mark -
#pragma mark -- Data manipulation --


- (void) updateData 
{
    [fullNoteTypesArray autorelease];
    fullNoteTypesArray = [[NoteType getNoteTypesToDisplay] retain];

    NSArray* notesArray=nil;
    
    if(self.censusObj.censusId > 0)
    {
        encounterCensusId = [Encounter_old getEncounterForCensus: self.censusObj.censusId
                                                            : self.censusObj.physicianNpi 
                                                            : _dateOfService];
        if(encounterCensusId > 0)
            notesArray = [EncounterNote getEncounterNotesToDisplay: encounterCensusId];
    }
	/*
    else if(apptId > 0)
    {
        encounterApptId = [Encounter getEncounterForAppt: apptId
                                                        : attendingPhysicianId
                                                        : dateOfService];
        if(encounterApptId > 0)
            notesArray = [EncounterNote getEncounterNotesToDisplay: encounterApptId];
    }*/
    
    // Create a map where the key is category type id, value is mutable array of notes
    NSMutableDictionary* tempNotesToCategoriesMap = [NSMutableDictionary dictionaryWithCapacity: 4];
    
    for (EncounterNote* note in notesArray)
    {
        NSMutableArray* notesByCategoryArray = [tempNotesToCategoriesMap objectForKey: [NSNumber numberWithInt: note.typeId]];
        if (!notesByCategoryArray)
        {
            notesByCategoryArray = [NSMutableArray arrayWithCapacity: 5];
            [tempNotesToCategoriesMap setObject: notesByCategoryArray forKey: [NSNumber numberWithInt: note.typeId]];
        }
        [notesByCategoryArray addObject: note];
    }
    
    
    [notesToCategoriesMap autorelease];
    notesToCategoriesMap = [[NSDictionary dictionaryWithDictionary: tempNotesToCategoriesMap] retain];
    
    // Create a nonempty note types array
    NSArray* keysArray = [notesToCategoriesMap allKeys];
    NSMutableArray* tempNoteTypesArray = [NSMutableArray arrayWithCapacity: [keysArray count]];

    // Fill an arrary of non-empty note types
    // Find the biggest note type id (will be used when insertig type ids)
    for (NoteType* noteType in fullNoteTypesArray)
    {
        NSNumber* noteTypeIdNumber = [NSNumber numberWithInt: noteType.noteTypeId];
        if ([keysArray containsObject: noteTypeIdNumber])
            [tempNoteTypesArray addObject: noteType];
        
        if (noteType.noteTypeId > biggestNoteTypeId)
            biggestNoteTypeId = noteType.noteTypeId;
    }

    [noteTypesArray autorelease];
    noteTypesArray = [[NSArray alloc] initWithArray: tempNoteTypesArray];
} // [EncounterNotesViewController updateData]


#pragma mark -
#pragma mark -- Functionality --

- (void) addNote: (id) sender
{
    if (!notesTable.hidden)
    {
        [notesTable removeFromSuperview];
        notesTable.hidden = YES;
        
        [self.view addSubview: noteTypesTable];
        noteTypesTable.hidden = NO;
    }
    
    if (notesTable.hidden && noteTypesTable.hidden)
    {
        [self.view addSubview: noteTypesTable];
        noteTypesTable.hidden = NO;
    }
    
    editButton.hidden = !notesTable.hidden;
} // [EncounterNotesViewController addNote]


- (void) showChat: (id) sender
{
    [super showChat];
} // [EncounterNotesViewController showChat:]


- (void) toggleEdit: (id) sender
{
    editButton.selected = !editButton.selected;
    
    // Edit note types table
    if (notesTable.hidden)
    {
        [noteTypesTable setEditing: !noteTypesTable.editing
                          animated: YES];
    }
} // [EncounterNotesViewController toggleEdit:]


- (void) clickFinish: (id) sender
{
    [self.navigationController popViewControllerAnimated: YES];
} // [EncounterNotesViewController clickFinish:]



@end
