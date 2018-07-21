//
//  CareTeamMemberDetailsViewController.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "CareTeamMemberDetailsView.h"
#import "CareTeamMemberDetailsTableViewCell.h"
#import "TableSectionHeaderWithLabel.h"
#import "CareTeamMember_old.h"

@interface CareTeamMemberDetailsViewController : QliqBaseViewController <UITableViewDelegate, UITableViewDataSource>
{
    CareTeamMemberDetailsView *careTeamMemberDetailsView;
	CareTeamMember_old *careTeamMember_;
}
@property (nonatomic, retain) CareTeamMember_old *careTeamMember;
@end
