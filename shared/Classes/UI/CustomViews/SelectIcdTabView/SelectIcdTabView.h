//
//  SelectIcdTabView.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 03/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SelectIcdTabView : UIView {

    UIButton *_favoritesButton;
    UIButton *_crosswalkButton;
    UIButton *_allButton;

    UILabel *_favoritesLabel;
    UILabel *_crosswalkLabel;
    UILabel *_allLabel;

}

@property (nonatomic, retain) UIButton *favoritesButton;
@property (nonatomic, retain) UIButton *crosswalkButton;
@property (nonatomic, retain) UIButton *allButton;

@property (nonatomic, retain) UILabel *favoritesLabel;
@property (nonatomic, retain) UILabel *crosswalkLabel;
@property (nonatomic, retain) UILabel *allLabel;

- (id)initWithFrame:(CGRect)frame withCrosswalk:(BOOL)yesNo;

@end
