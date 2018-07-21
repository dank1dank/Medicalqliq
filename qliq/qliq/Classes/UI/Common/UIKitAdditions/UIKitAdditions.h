//
//  UIKitAdditions.h
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIAlertView_Blocks.h"
#import "UIActionSheet_Blocks.h"

#import "MFMessageComposeViewController_Blocks.h"
#import "MFMailComposeViewController_Blocks.h"

#import "UIView_Shortcuts.h"
#import "NSError_Shortcuts.h"

#define UIViewAutoresizingFlexibleVerticalMargins UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin
#define UIViewAutoresizingFlexibleHorisontalMargins UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin
#define UIViewAutoresizingFlexibleMargins UIViewAutoresizingFlexibleHorisontalMargins | UIViewAutoresizingFlexibleVerticalMargins
#define UIViewAutoresizingFlexibleSize UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
#define UIViewAutoresizingAll UIViewAutoresizingFlexibleSize | UIViewAutoresizingFlexibleMargins