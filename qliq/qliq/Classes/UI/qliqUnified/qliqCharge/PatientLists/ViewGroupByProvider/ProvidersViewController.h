//
//  ProvidersViewController.h
//  qliq
//
//  Created by Paul Bar on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "TableSectionHeader.h"
#import "SliderView.h"

@class ProvidersView;

@interface ProvidersViewController : QliqBaseViewController <UITableViewDelegate, UITableViewDataSource, TableSectionHeaderDelegate, SliderViewDelegate>
{
    ProvidersView *providersView;
}

@end
