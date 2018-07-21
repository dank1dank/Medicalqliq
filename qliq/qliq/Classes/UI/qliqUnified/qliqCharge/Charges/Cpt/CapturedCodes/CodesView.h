//
//  CodesView.h
//  qliq
//
//  Created by Paul Bar on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseView.h"

@class PatientHeaderView;

@interface CodesView : QliqBaseView

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) PatientHeaderView *patientHeaderView;

@end
