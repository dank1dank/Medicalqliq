//
//  EncountersForDateViewController.h
//  qliq
//
//  Created by Paul Bar on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "HorizontalPickerView.h"
#import "CensusFactoryProtocol.h"
#import "SliderView.h"

@class EncountersForDateView;
@class PlainListCensusesFactory;

@interface EncountersForDateViewController : QliqBaseViewController <HorizontalPickerViewDelegate, UITableViewDelegate, UITableViewDataSource, SliderViewDelegate, UISearchDisplayDelegate>
{
    EncountersForDateView *encountersView;
    HorizontalPickerView *horizontalPickerView;
    
    NSMutableArray *pickerViewArray;
}

@property (nonatomic, assign) NSInteger futureDaysToShow;
@property (nonatomic, assign) NSInteger pastDaysToShow;
@property (nonatomic, retain) id<CensusFactoryProtocol> censusesFactory;
@property (nonatomic, retain) NSString *filterDescription;

@end
