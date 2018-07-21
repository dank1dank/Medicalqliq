//
//  QliqSwitch.h
//  qliq
//
//  Created by Aleksey Garbarev on 17/10/12.
//
//

#import "RCSwitch.h"

#define QliqSwitchDefaultSize CGSizeMake(70, 28)

@interface QliqSwitch : RCSwitch

@property (nonatomic, strong) NSObject * context;

@end