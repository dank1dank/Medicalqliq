//
//  ReportIncidentService.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface RegisterAccountService : QliqAPIService

- (id) initWithUser:(QliqUser *)_user andOrganization:(NSString *)_organization andWebsite:(NSString *)_website;

@end
