//
//  EncryptedSipMessage.h
//  qliq
//
//  Created by Adam on 12/3/12.
//
//

#import <Foundation/Foundation.h>

@interface EncryptedSipMessage : NSObject

@property (nonatomic, readwrite) int messageId;
@property (nonatomic, strong) NSString *fromQliqId;
@property (nonatomic, strong) NSString *toQliqId;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, readwrite) NSTimeInterval timestamp;
@property (nonatomic, strong) NSString *mime;
@property (nonatomic, strong) NSDictionary *extraHeaders;

- (BOOL) isEmpty;

@end
