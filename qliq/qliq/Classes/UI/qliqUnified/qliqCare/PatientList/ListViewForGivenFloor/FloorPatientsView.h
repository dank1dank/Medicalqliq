//
//  FloorPatientsView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NurseTabView.h"

@interface FloorPatientsView : UIView
{
    UIView *headerBackgroundView;
    UILabel *hospitalNameLabel;
    UITableView *patientsTable_;
    NurseTabView *tabView_;
}

@property (nonatomic, readonly) UITableView *patientsTable;
@property (nonatomic, readonly) NurseTabView *tabView;
@property (nonatomic, assign) NSString *hospitalName;

@end
