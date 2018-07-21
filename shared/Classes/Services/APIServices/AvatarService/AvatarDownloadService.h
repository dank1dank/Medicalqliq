//
//  AvatarAPIService.h
//  qliq
//
//  Created by Aleksey Garbarev on 15.08.12.
//
//

#import "QliqAPIService.h"

@interface AvatarDownloadService : QliqAPIService

- (id)initWithUser:(QliqUser *)user andUrlString:(NSString *)urlString;

@end
