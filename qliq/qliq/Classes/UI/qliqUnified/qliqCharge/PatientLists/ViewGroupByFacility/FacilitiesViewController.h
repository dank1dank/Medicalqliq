//
//  FacilitiesViewController.h
//  qliq
//
//  Created by Paul Bar on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "TableSectionHeader.h"
#import "SliderView.h"

@class FacilitiesView;

@interface FacilitiesViewController : QliqBaseViewController <UITableViewDelegate, UITableViewDataSource, TableSectionHeaderDelegate, SliderViewDelegate>
{
    FacilitiesView *facilitiesView;
}
@end
