//
//  FloorViewController.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "FloorView.h"
#import "FloorRoomsTableViewCell.h"
#import "NurseTabView.h"
#import "FloorTableSectionHeader.h"
#import "RoomPlaceView.h"
#import "FloorPatientsViewController.h"
#import "CareTeamViewController.h"
#import "AlertsViewController.h"

@interface FloorViewController : QliqBaseViewController <UITableViewDelegate, UITableViewDataSource, NurseTabViewDelegate, FloorRoomsTableViewCellDelegate>
{
    FloorView *floorView;
    
    NSMutableArray *roomsArray;
    
    //TIP:
    Floor_old *floor_;
}

@property (nonatomic, retain) Floor_old* floor;
@end
