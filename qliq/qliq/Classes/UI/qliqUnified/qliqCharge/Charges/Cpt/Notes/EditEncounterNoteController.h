#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"
#import "PatientHeaderView.h"
#import "Census_old.h"
#import "Patient_old.h"

@class EncounterNote;
@class NoteType;

@interface EditEncounterNoteController : QliqBaseViewController <PatientHeaderViewDelegate>
{
    Patient_old* patient;
	
    NSTimeInterval _dateOfService;
    NoteType* noteType;
    EncounterNote* note;

    
    UIView* topInfoPane;
    UITextView* noteTextView;

    UILabel* noteTypeLabel;
    UILabel* persistNoteLabel;
    
    UIButton* persistNoteButton;
    PatientHeaderView *patientView;
	
}

//@property (nonatomic, retain) Patient* patient;
@property (nonatomic, assign) NSTimeInterval dateOfService;
@property (nonatomic, retain) Census_old* censusObj;
@property (nonatomic, assign) NoteType* noteType;
@property (nonatomic, retain) EncounterNote* note;


@end
