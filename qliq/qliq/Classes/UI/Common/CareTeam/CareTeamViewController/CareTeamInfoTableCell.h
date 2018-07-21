//
//  CareTeamInfoTableCell.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CareTeamInfoTableCell;

@protocol CareTeamInfoTableCellDelegate

-(void) selectedCell:(CareTeamInfoTableCell*)cell;

@end

@interface CareTeamInfoTableCell : UITableViewCell
{
    UIView *separator1;
    UIView *separator2;
    
    UIImageView *callView;
    UIImageView *chatView;
    
    UITapGestureRecognizer *tapRecognizer;
    
    id<CareTeamInfoTableCellDelegate> delegate_;
    
}

@property (nonatomic, assign) id<CareTeamInfoTableCellDelegate> delegate;


@end
