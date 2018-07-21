#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"
#import "SectionHeaderView.h"
#import "Census_old.h"
#import "Patient_old.h"

@class StretchableButton;

@interface EncounterNotesViewController : QliqBaseViewController   <UITableViewDataSource, UITableViewDelegate,
                                                                    UITextFieldDelegate, UIScrollViewDelegate,
                                                                    PatientHeaderViewDelegate, SectionHeaderViewDelegate>
{
    // move to initializer since we anyway can't work without it
    Patient_old* patient;
	
    NSTimeInterval _dateOfService;
    /*
    NSInteger censusId;
    NSInteger apptId;
    NSInteger attendingPhysicianId;
	 */

    NSInteger encounterCensusId;
    NSInteger encounterApptId;
	Census_old *censusObj;
    
    UITableView* notesTable;
    UITableView* noteTypesTable;
    
    UIView* buttonView;
    StretchableButton* editButton;
    StretchableButton* finishButton;
    
    NSUInteger biggestNoteTypeId;
    
    // an array od note types
    NSArray* noteTypesArray;
    NSArray* fullNoteTypesArray;
    
    // a map where the key is category type id, value is mutable array of notes
    NSDictionary* notesToCategoriesMap;
    
    NSUInteger expandedSection;
    BOOL expandingInProgress;
    PatientHeaderView *patientView;
	
}
/*
@property (nonatomic, retain) Patient* patient;
@property (nonatomic, assign) NSInteger censusId;
@property (nonatomic, assign) NSInteger apptId;
@property (nonatomic, assign) NSInteger attendingPhysicianId;
*/
@property (nonatomic, assign) NSTimeInterval dateOfService;
@property (nonatomic, retain) Census_old* censusObj;

@end
