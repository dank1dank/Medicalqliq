//
//  EncountersForDateView.h
//  qliq
//
//  Created by Paul Bar on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseView.h"

@class HorizontalPickerView;

@interface EncountersForDateView : QliqBaseView

@property(nonatomic, retain) HorizontalPickerView *horizontalPickerView;
@property(nonatomic, readonly) UITableView* tableView;

@end
