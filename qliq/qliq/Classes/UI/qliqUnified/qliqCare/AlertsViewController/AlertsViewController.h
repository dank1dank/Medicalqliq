//
//  AlertsViewController.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "FloorPatientsView.h"
#import "PatientTableViewCell.h"
#import "SelectPersonViewController.h"

typedef enum
{
    NurseHandoffStateGiveStart = 0,
    NurseHandoffStateGiveSelectPatients,
    NurseHandoffStateGiveSelectNurse,
    NurseHandoffStateTakeStart,
    NurseHandoffStateTakeSelectPatients
}NurseHandoffState;

@interface AlertsViewController : QliqBaseViewController <UITableViewDelegate, UITableViewDataSource, NurseTabViewDelegate, PatientTableViewCellDelegate, SelectPersonViewControllerDelegate>
{
    FloorPatientsView *alertsView;
    NurseHandoffState state;
}
@end
