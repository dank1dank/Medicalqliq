//
//  MFMessageComposeViewController_Blocks.h
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface MFMessageComposeViewController_Blocks : MFMessageComposeViewController

- (void)presentFromViewController:(UIViewController *)viewController animated:(BOOL)animated finish:(void(^)(MessageComposeResult result))result;

@end
