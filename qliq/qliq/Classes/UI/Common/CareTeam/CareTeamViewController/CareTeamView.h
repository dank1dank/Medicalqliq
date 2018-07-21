//
//  CareTeamView.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NurseTabView.h"

@protocol CareTeamViewDelegate

-(void) headerSelected;

@end

@interface CareTeamView : UIView <UIGestureRecognizerDelegate>
{
    UIImageView *headerView;
    UIImageView *patientPhotoView;
    UILabel *patientNameLabel;
    UIImageView *disclosureIndicator;
    
    UITableView *infoTable_;
    NurseTabView *tabView_;
    
    UITapGestureRecognizer *tapRecognizer;
    
    id<CareTeamViewDelegate> delegate_;
}

@property (nonatomic, assign) NSString *patientName;
@property (nonatomic, assign) UIImage *patientPhoto;
@property (nonatomic, readonly) NurseTabView *tabView;
@property (nonatomic, readonly) UITableView *infoTable;

@property (nonatomic, assign) id<CareTeamViewDelegate> delegate;

@end
