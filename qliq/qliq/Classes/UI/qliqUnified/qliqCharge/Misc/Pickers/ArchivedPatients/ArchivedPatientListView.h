// Created by Developer Toy
//ArchivedPatientListView.h

#import <UIKit/UIKit.h>
#import "Helper.h"
#import "QliqBaseViewController.h"

@interface ArchivedPatientListView : QliqBaseViewController <UITabBarControllerDelegate,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>
{
	NSMutableArray *patientPickerList;
	NSMutableArray *searchPickerList;
    UITableView *tblPatientList;
    UISearchBar *searchbarPatients;
    BOOL _isContentInset;
    BOOL _isSearching;

	double physicianNpi;
	NSString *admitDate;
	NSString *adding;
}
//RA:
@property (nonatomic, readwrite) double physicianNpi;
@property (nonatomic, retain) NSString *admitDate;
@property (nonatomic, retain) NSString *adding;


@end