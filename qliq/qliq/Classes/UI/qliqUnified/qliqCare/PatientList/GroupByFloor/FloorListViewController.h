//
//  FloorListViewController.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "FloorListView.h"
#import "FloorListTableViewCell.h"
#import "NurseTabView.h"
#import "FloorViewController.h"
#import "AlertsViewController.h"

@interface FloorListViewController : QliqBaseViewController <UITableViewDataSource, UITableViewDelegate, NurseTabViewDelegate>
{
    FloorListView *floorListView;
    NSMutableArray *floorArray;
	User *_userObj;
}
@property (nonatomic, retain) User *userObj;

@end
