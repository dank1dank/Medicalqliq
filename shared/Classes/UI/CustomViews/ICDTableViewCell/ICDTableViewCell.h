//
//  ICDTableViewCell.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ICDTableViewCell : UITableViewCell {
    UIImageView *_favoriteView;
    UIImageView *_crosswalkView;
	UIImageView *_selectedView;
}

@property (nonatomic, assign, getter = isFavorite) BOOL favorite;
@property (nonatomic, assign, getter = isCrosswalk) BOOL crosswalk;
@property (nonatomic, assign, getter = isSelected) BOOL selected;
@property (nonatomic, assign) BOOL visibledIndicators;
@property (nonatomic, assign, getter = isPrimaryIcd) BOOL primaryIcd;

@end
