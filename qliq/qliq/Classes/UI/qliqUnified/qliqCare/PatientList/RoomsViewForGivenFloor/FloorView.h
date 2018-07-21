//
//  FloorView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NurseTabView.h"
#import "UserHeaderView.h"

@interface FloorView : UIView
{
    UIView *headerBackgroundView;
    UILabel *floorNameLabel;
    UITableView *floorTable_;
    NurseTabView *tabView_;

}

@property (nonatomic, readonly) UITableView *floorTable;
@property (nonatomic, readonly) NurseTabView *tabView;
@property (nonatomic, assign) NSString *floorName;
@end
