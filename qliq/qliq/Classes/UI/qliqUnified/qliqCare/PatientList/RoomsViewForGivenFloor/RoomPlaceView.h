//
//  RoomPlaceView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Patient_old.h"

@interface RoomPlaceView : UIView
{
    UILabel *patientNameLabel;
    UILabel *nurseNameLabel;
    UILabel *emptyLabel;
    Patient_old *patient_;
	
    BOOL empty_;
}

@property (nonatomic, assign) NSString *patientName;
@property (nonatomic, assign) NSString *nurseName;
@property (nonatomic, assign) BOOL empty;
@property (nonatomic, retain) Patient_old *patient;
@end
