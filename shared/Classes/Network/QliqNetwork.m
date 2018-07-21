//
//  QliqNetwork.m
//  qliq
//
//  Created by Aleksey Garbarev on 10/5/12.
//
//

#import "QliqNetwork.h"

@interface QliqNetwork ()
@property (nonatomic, strong) QliqReachability * reachability;
@property (nonatomic, strong) QliqProgressHandlers * progressHandlers;
@property (nonatomic, strong) QliqPresences * presences;
@end

@implementation QliqNetwork
@synthesize reachability;
@synthesize progressHandlers;
@synthesize presences;

static QliqNetwork *s_instance = nil;

- (id) init{
    self = [super init];
    if (self){
        self.reachability = [[QliqReachability alloc] init];
        [QliqReachability setSharedInstance:self.reachability];
        [self.reachability startListening];
        
        self.progressHandlers = [[QliqProgressHandlers alloc] init];
        self.presences = [[QliqPresences alloc] init];
    }
    return self;
}


- (void)dealloc{
    [self.reachability stopListening];
    [QliqReachability setSharedInstance:nil];
}

+ (QliqNetwork *)sharedInstance {
    return s_instance;
}

+ (void) setSharedInstance:(QliqNetwork *)instance {
    s_instance = instance;
}


- (BOOL) hasIPAddressChanged:(BOOL)update
{
    return [self.reachability hasIPAddressChanged:update];
}

@end
