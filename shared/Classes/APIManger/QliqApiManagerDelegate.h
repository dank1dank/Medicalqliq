//
//  QliqApiManagerDelegate.h
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QliqApiManagerDelegate <NSObject>

@optional

//login
- (void)apiManagerDidLogInWithGroupInfo:(NSString *)groupInfo;
- (void)apiManagerDidFailLogInWithReason:(NSString *)reason;


@end
