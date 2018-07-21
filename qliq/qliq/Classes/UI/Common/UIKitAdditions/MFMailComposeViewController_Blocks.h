//
//  MFMailComposeViewController_Blocks.h
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface MFMailComposeViewController_Blocks : MFMailComposeViewController

- (void)presentFromViewController:(UIViewController *)viewController animated:(BOOL)animated finish:(void(^)(MFMailComposeResult result, NSError * error))result;

@end
