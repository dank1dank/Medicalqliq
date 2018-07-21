//
//  TouchTableViewDelegate.h
//  cpts-touch
//
//  Created by Pascal Pfiffner on 28.08.08.
//  This sourcecode is released under the Apache License, Version 2.0
//  http://www.apache.org/licenses/LICENSE-2.0.html
//  
//  Protocol for the delegate of the CptUpdater
// 

#import <Foundation/Foundation.h>
@class CptUpdater;

@protocol CptUpdaterDelegate <NSObject>

- (void) updaterDidStartAction:(CptUpdater *)updater;
- (void) updater:(CptUpdater *)updater didEndActionSuccessful:(BOOL)success;

@optional

- (void) updater:(CptUpdater *)updater progress:(CGFloat)progress;

@end
