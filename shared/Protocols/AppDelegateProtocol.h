//
//  AppDelegateProtocol.h
//  QliqCharge
//
//  Created by Paul Bar on 11/26/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class IdleEventController;
@class QliqTabBarControllerOld;

@protocol AppDelegateProtocol <NSObject>

@property (nonatomic, readonly) IBOutlet IdleEventController *idleController;

- (void)shareMedia:(NSArray *)mediaFiles;

@end
