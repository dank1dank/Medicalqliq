//
//  GetGroupInfoService.h
//  qliq
//
//  Created by Ravi Ada on 08/01/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqApiManagerDelegate.h"
#import "QliqJsonSchemaHeader.h"
#import "ApiServiceBase.h"

@class QliqGroup;

@protocol GetGroupInfoServiceDelegate <NSObject>

- (void)getGroupInfoSuccess;
- (void)didFailToGetGroupInfoWithReason:(NSString *)reason;
                
@end

@interface GetGroupInfoService : ApiServiceBase

+ (GetGroupInfoService *)sharedService;

+ (QliqGroup *)parseGroupJson:(NSDictionary *)dataDict andSaveInDb:(BOOL)saveInDb;

- (void)getGroupInfo:(NSString *)qliqId;
- (void)getGroupInfo:(NSString *)qliqId withCompletion:(void(^)(QliqGroup *group, NSError *error))completeBlock;

@property (nonatomic, assign) id<GetGroupInfoServiceDelegate> delegate;

@end
