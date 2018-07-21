//
//  QliqDBServiceTests.m
//  qliq
//
//  Created by Aleksey Garbarev on 12/5/12.
//
//

#import "QliqDBServiceTests.h"
#import "Recipients.h"

#import "QliqDBService.h"
#import "DBCoder_DBService.h"

#import "QliqUser.h"
#import "QliqUserDBService.h"

#import "DBUtil.h"

@interface TestingRecipient : NSObject<Recipient>
@property (nonatomic, strong) NSString * recipientQliqId;

@end
@implementation TestingRecipient
@synthesize recipientQliqId;
@end


@implementation QliqDBServiceTests


- (void) testSimpleUpdateQuery{
    
    
    Recipients * recipients = [[Recipients alloc] init];
    for (int i = 0; i < 20; i++){
        TestingRecipient * recipient = [TestingRecipient new];
        recipient.recipientQliqId = [NSString stringWithFormat:@"%d",i*20];
        [recipients addRecipient:recipient];
    }
    
    DBCoder * coder = [[DBCoder alloc] initWithDBObject:recipients];
    
    [coder updateStatement:^(NSString *query, NSArray *args) {
        NSLog(@"query: %@ args: %@",query, args);
    }];
    
    [coder insertStatement:^(NSString *query, NSArray *args) {
        NSLog(@"query: %@ args: %@",query, args);
    } replace:NO];
    
    [coder deleteStatement:^(NSString *query, NSArray *args) {
        NSLog(@"query: %@ args: %@",query, args);
    }];
    

    
}

@end
