//
//  MFMailComposeViewController_Blocks.m
//  qliq
//
//  Created by Aleksey Garbarev on 29.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MFMailComposeViewController_Blocks.h"

@interface MFMailComposeViewController_Blocks () <MFMailComposeViewControllerDelegate>
{
    void(^finishBlock)(MFMailComposeResult result, NSError * error);
}

@end

@implementation MFMailComposeViewController_Blocks

- (void)presentFromViewController:(UIViewController *)modalViewController animated:(BOOL)animated finish:(void(^)(MFMailComposeResult result, NSError *error))result {
    
    finishBlock = result;
    self.mailComposeDelegate = self;
    
    [modalViewController presentViewController:self animated:animated completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (finishBlock) {
        finishBlock(result,error);
    }
}



@end
