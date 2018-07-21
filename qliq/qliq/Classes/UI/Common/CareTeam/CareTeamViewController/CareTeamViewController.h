//
//  CareTeamViewController.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "CareTeamView.h"
#import "NurseTabView.h"
#import "TableSectionHeader.h"
#import "TableSectionHeaderWithLabel.h"
#import "CareTeamInfoTableCell.h"
#import "PatientDemographicsViewController.h"
#import "CareTeamMemberDetailsViewController.h"
#import "AlertsViewController.h"
#import "Patient_old.h"

@interface CareTeamViewController : QliqBaseViewController <TableSectionHeaderDelegate, UITableViewDataSource, UITableViewDelegate, NurseTabViewDelegate, CareTeamViewDelegate, CareTeamInfoTableCellDelegate>
{
    CareTeamView *careTeamView;
    //TIP:
    Patient_old *patient_;
	NSMutableDictionary *careTeamDict;
	NSMutableArray *careTeamTypesArray;
}

@property (nonatomic, retain) Patient_old *patient;

@end