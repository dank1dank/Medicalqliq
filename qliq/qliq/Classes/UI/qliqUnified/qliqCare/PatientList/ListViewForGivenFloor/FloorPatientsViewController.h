//
//  FloorPatientsViewController.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "FloorPatientsView.h"
#import "NurseTabView.h"
#import "PatientTableViewCell.h"
#import "FloorPatientsTableSectionHeader.h"
#import "FloorViewController.h"
#import "AlertsViewController.h"
#import "Facility_old.h"

@interface FloorPatientsViewController : QliqBaseViewController <UITableViewDelegate, UITableViewDataSource, NurseTabViewDelegate>
{
    FloorPatientsView *floorPatientsView;
    
    NSMutableArray *patientsArray;
    
    //TIP:
	 Floor_old *floor_;
}

@property (nonatomic, retain) Floor_old* floor;

@end
