//
//  FloorListView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NurseTabView.h"
@interface FloorListView : UIView
{
    UIView *headerBackgroundView;
    UILabel *hospitalNameLabel;
    UITableView *floorTable_;
    NurseTabView *tabView_;
}

@property (nonatomic, readonly) UITableView *floorTable;
@property (nonatomic, readonly) NurseTabView *tabView;
@property (nonatomic, assign) NSString *hospitalName;


@end
