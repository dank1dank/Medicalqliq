//
//  AppointmentTableViewCell.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 6/6/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AppointmentTableViewCell : UITableViewCell {
    
}

@property (nonatomic, retain) UILabel *lblRoom;
@property (nonatomic, retain) UILabel *lblPatientName;
@property (nonatomic, retain) UILabel *lblPatientAgeGenderRace;
@property (nonatomic, retain) UILabel *lblDate;
@property (nonatomic, retain) UILabel *lblFacilityType;
@property (nonatomic, retain) UILabel *lblReason;
@property (nonatomic, retain) UIImageView *statusImage;

@property (nonatomic, assign) BOOL showStatusImage;

@end
