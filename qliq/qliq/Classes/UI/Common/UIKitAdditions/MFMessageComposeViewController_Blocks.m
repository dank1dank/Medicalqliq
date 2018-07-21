//
//  MFMessageComposeViewController_Blocks.m
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MFMessageComposeViewController_Blocks.h"

@interface MFMessageComposeViewController_Blocks () <MFMessageComposeViewControllerDelegate>
{
    void(^finishBlock)(MessageComposeResult);
}

@end

@implementation MFMessageComposeViewController_Blocks

- (void)presentFromViewController:(UIViewController *)modalViewController animated:(BOOL)animated finish:(void(^)(MessageComposeResult ))result {
    finishBlock = result;
    self.messageComposeDelegate = self;
    [modalViewController presentViewController:self animated:animated completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    if (finishBlock) {
        finishBlock(result);
    }
}


@end
