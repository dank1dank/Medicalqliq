//
//  BusyAlertController.h
//  qliq
//
//  Created by Aleksey Garbarev on 08.08.13.
//
//

#import <Foundation/Foundation.h>

@interface BusyAlertController : NSObject

- (void) setNeedSipRegister;
- (void) sendSipRegisterIfNeeded;


- (void) sendSipRegister;
- (void) sendSipRegisterWhenApplicationActive;

@end
