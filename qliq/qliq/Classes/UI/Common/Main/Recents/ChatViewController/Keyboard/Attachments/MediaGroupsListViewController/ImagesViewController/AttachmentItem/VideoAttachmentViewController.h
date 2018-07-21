//
//  VideoView.h
//  test
//
//  Created by Aleksey Garbarev on 24.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseAttachmentViewController.h"

@class MessageAttachment;

@interface VideoAttachmentViewController : BaseAttachmentViewController

@property (nonatomic, strong) RemoveBlock removeBlock;

@end
