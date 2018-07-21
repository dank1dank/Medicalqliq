//
//  SipContact.h
//  qliq
//
//  Created by Adam Sowa on 12/7/12.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "QliqDBService.h"

typedef enum {
    SipContactTypeUnknown = 0,
    SipContactTypeUser = 1,
    SipContactTypeGroup = 2,
    SipContactTypeMultiPartyChat = 3
} SipContactType;

//@protocol SipContact <NSObject>
//
//- (NSString *) qliqId;
//- (NSString *) sipUri;
//- (NSString *) privateKey;
//- (NSString *) publicKey;
//- (SipContactType) type;
//
//@end

@interface SipContact : NSObject<DBCoding>

@property (nonatomic, strong) NSString * qliqId;
@property (nonatomic, strong) NSString * sipUri;
@property (nonatomic, strong) NSString * privateKey;
@property (nonatomic, strong) NSString * publicKey;
@property (nonatomic, readwrite) SipContactType sipContactType;


@end
