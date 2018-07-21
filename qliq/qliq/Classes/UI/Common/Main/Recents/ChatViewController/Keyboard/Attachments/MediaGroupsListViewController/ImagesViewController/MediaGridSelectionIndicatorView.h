//
//  MediaGridSelectionIndicatorView.h
//  qliqConnect
//
//  Created by Valerii Lider on 08/13/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaGridSelectionIndicatorView : UIView
{
    UIView *backgroundView;
    UIImageView *selectedCheckbox;
}

-(void) hide;
-(void) show;
@end
