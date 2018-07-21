//
//  EncountersTableSearchView.h
//  qliq
//
//  Created by Paul Bar on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EncountersTableSearchView : UIView <UITextFieldDelegate>
{
    UIImageView *searchBarBackground;
    UITextField *textField;
    UIButton *searchButton;
}

@end
