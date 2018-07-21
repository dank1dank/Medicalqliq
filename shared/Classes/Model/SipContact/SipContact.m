

#import "SipContact.h"


@implementation SipContact
@synthesize qliqId, sipUri, privateKey, publicKey, sipContactType;

- (void)encodeWithDBCoder:(DBCoder *)coder{
    
    [coder encodeObject:self.qliqId forColumn:@"contact_qliq_id"];
    [coder encodeObject:self.sipUri forColumn:@"sip_uri"];
    [coder encodeObject:self.privateKey forColumn:@"private_key"];
    [coder encodeObject:self.publicKey forColumn:@"public_key"];
    [coder encodeObject:[NSNumber numberWithInteger:self.sipContactType] forColumn:@"type"];
}

- (id)initWithDBCoder:(DBCoder *)decoder{
    
    self = [super init];
    if (self) {
        self.qliqId = [decoder decodeObjectForColumn:@"contact_qliq_id"];
        self.sipUri = [decoder decodeObjectForColumn:@"sip_uri"];
        self.privateKey = [decoder decodeObjectForColumn:@"private_key"];
        self.publicKey = [decoder decodeObjectForColumn:@"public_key"];
        self.sipContactType = (SipContactType)[[decoder decodeObjectForColumn:@"type"] integerValue];
    }
    return self;
}

- (NSString *)dbPKProperty{
    return @"qliqId";
}

+ (NSString *)dbPKColumn{
    return @"contact_qliq_id";
}

+ (NSString *)dbTable{
    return @"sip_contact";
}


@end