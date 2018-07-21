//
//  CareTeamMemberDetailsView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CareTeamMemberDetailsTabView.h"

@interface CareTeamMemberDetailsView : UIView
{
    UIImageView *headerView;
    UIImageView *favoritesView;
    UILabel *physicianNameLabel;
    
    UITableView *infoTable_;
    CareTeamMemberDetailsTabView *tabView;
}

@property (nonatomic, assign) NSString *providerName;
@property (nonatomic, assign) UIImage *favoritesViewImage;
@property (nonatomic, readonly) UITableView *infoTable;

@end
