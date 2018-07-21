//
//  PatientDemographicsViewController.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "PatientDemographicsView.h"
#import "TableSectionHeader.h"
#import "TableSectionHeaderWithLabel.h"
#import "PatientDemographicsTableViewCell.h"
#import "PatientDemographicsTableCellLabelGroup.h"
#import "Patient_old.h"
#import "Census_old.h"

@interface PatientDemographicsViewController : QliqBaseViewController <UITableViewDataSource, UITableViewDelegate>
{
    PatientDemographicsView *patientDemographicsView;
	Patient_old *patient_;
	Census_old	*censusObj;
	NSMutableArray *patientContactsArray;
}
@property (nonatomic, retain) Patient_old *patient;

@end
