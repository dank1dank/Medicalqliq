//
//  FloorTableViewCell.h
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoomPlaceView.h"

@class FloorRoomsTableViewCell;

@protocol FloorRoomsTableViewCellDelegate <NSObject>

-(void) floorRoomsTableViewCell:(FloorRoomsTableViewCell*)cell didSelectRoomPlaceAtIndex:(NSInteger) index;

@end

@interface FloorRoomsTableViewCell : UITableViewCell
{
    NSMutableArray *separators;
    NSMutableArray *roomPlaces;
    
    UITapGestureRecognizer *tapRecognizer;
    
    id<FloorRoomsTableViewCellDelegate> delegate_;
}

@property (nonatomic, assign) id<FloorRoomsTableViewCellDelegate> delegate;
@property (nonatomic, assign) NSUInteger numOfSections;

-(RoomPlaceView*) roomPlaceViewWithIndex:(NSInteger)index;

@end
