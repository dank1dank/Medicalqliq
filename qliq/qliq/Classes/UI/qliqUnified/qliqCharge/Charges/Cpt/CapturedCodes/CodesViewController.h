//
//  CodesViewController.h
//  qliq
//
//  Created by Paul Bar on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "SliderView.h"
#import "HorizontalPickerView.h"

@class CodesView;
@class PatientVisit;

@interface CodesViewController : QliqBaseViewController<SliderViewDelegate, HorizontalPickerViewDelegate>
{
    CodesView *codesView;
    HorizontalPickerView *horizontalPickerView;
    NSMutableArray *pickerViewArray;
}

@property (nonatomic, retain) PatientVisit* patientVisit;
@property (nonatomic, retain) NSDate* selectedDate;

@end
