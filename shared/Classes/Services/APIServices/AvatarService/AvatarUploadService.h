//
//  SetAvatar.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface AvatarUploadService : QliqAPIService

- (id) initWithAvatar:(UIImage *)image forUser:(QliqUser *)user;

@end
