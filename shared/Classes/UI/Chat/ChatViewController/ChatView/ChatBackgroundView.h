//
//  ChatBackgroundView.h
//  qliq
//
//  Created by Paul Bar on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ChatView;

@interface ChatBackgroundView : UIView
{
    ChatView *chatView;
}

@property (nonatomic, readonly) ChatView *chatView;
@property (nonatomic, assign) CGFloat keyboardHeight;

@end
