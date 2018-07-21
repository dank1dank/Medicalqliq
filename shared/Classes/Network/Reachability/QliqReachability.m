//
//  QliqReachability.m
//  qliq
//
//  Created by Aleksey Garbarev on 10/5/12.
//
//

#import "QliqReachability.h"
#import "Reachability.h"

#import "RestClient.h"
#import "QliqSip.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"


/*
 Issues:
 1. QliqSip handleNetworkDown isn't called when reachability is off
 2. Check for !sipReachable when reachability goes on can cause the sip not to restart
 */

NSString * QliqReachabilityChangedNotification = @"QliqReachabilityChangedNotification";
static __weak QliqReachability *s_instance = nil;

@implementation QliqReachability{
    NetworkStatus restReachabilityStatus;
    
    BOOL sipReachable;
    
    BOOL notifyReachabilityChanges;
    
    BOOL userWasRegistered;
    
    NSString *hostIP;
}


- (id) init{
    self = [super init];
    if (self){
        restReachabilityStatus = ReachableViaWWAN;
        sipReachable = NO;
        notifyReachabilityChanges = NO;
        userWasRegistered = NO;
        hostIP = [self getIPAddress:YES];
    }
    return self;
}

+ (QliqReachability *) sharedInstance
{
    if (s_instance == nil) {
        s_instance = [[QliqReachability alloc] init];
    }
    return s_instance;
}

+ (void) setSharedInstance:(QliqReachability *)instance
{
    s_instance = instance;
}

- (BOOL) wasRegistered{
    return userWasRegistered;
}

- (void) notifyReachabilityChanged {
    
    if (notifyReachabilityChanges){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:QliqReachabilityChangedNotification object:self];
        });
    }
}

- (void) restClientReachabilityChanged:(NSNotification *) restClientNotification{
    NetworkStatus status = [[[restClientNotification userInfo] valueForKey:@"networkStatus"] intValue];
    
    DDLogSupport(@"restclient reachability status is %ld. previously reachability status is %ld",(long)status, (long)restReachabilityStatus);
    
    // 8/6/2014 - Krishna
    // If user logged out, ignore this
    //
    AppDelegate *appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
    UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
    
    if ([appDelegate isUserLoggedOut])
    {
        DDLogSupport(@"User not logged in. Do nothing.");
        return;
    }
    
    // 8/25/2014 - Krishna
    // Shutting down transport in BG, Battery Save mode ON
    // caused a crash
    //
    if (appDelegate.appInBackground == YES && userSettings.isBatterySavingModeEnabled == YES)
    {
        DDLogSupport(@"App is in BG with Battery save mode ON. Do nothing.");
        return;
    }
    
    if (restReachabilityStatus != status){
        restReachabilityStatus = status;
        
        // I removed the check for sipReachable from here because SIP doesn't know it is
        // disconnect until it tries to send anything, so depending on the flag can cause
        // the code to ignore network up event for SIP. - Adam Sowa
        //
        if ([self restReachable]) {
            // reachability changed shutdown transport and restart SIP
            //
            // Krishna 2/15/2017
            [appDelegate shutdownReconnectSIP];
        }
        else {
            // Krishna 4/9/2015
            // No need of Unregistering if the reachability is not there
            // We should instead try to shutdown the transport.
            //
            [[QliqSip sharedQliqSip] shutdownTransport];
        }
        
        [self notifyReachabilityChanged];
    } else {
         [[QliqSip sharedQliqSip] setRegistered:YES];
    }
}

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP)  || (interface->ifa_flags & IFF_LOOPBACK)  ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

- (BOOL) hasIPAddressChanged:(BOOL)update
{
    NSString *newHostIP = [self getIPAddress:YES];
    if ([newHostIP isEqualToString:hostIP])
    {
        DDLogSupport(@"IP Address is Not changed: %@", newHostIP);
        return NO;
    }
    else {
        DDLogSupport(@"IP Address is Changed from %@ to %@", hostIP, newHostIP);
        if (update)
            hostIP = newHostIP;
        return YES;
    }
}

- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    DDLogSupport(@"Local IP addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    
    return address ? address : @"0.0.0.0";
}

- (void) sipUnregistrationEvent: (NSNotification *)sipNotification {
    NSInteger status = [[[sipNotification userInfo] valueForKey:@"status"]  intValue];
    DDLogSupport(@"UNREGISTER, status: %ld", (long)status);
    // Krishna 8/4/2014
    // Unregistered so shutdown transports
    // Shutdown tranports if we got 200.Which means transports are good.
    if (status == 200)
       [[QliqSip sharedQliqSip] shutdownTransport];
}

- (void) sipRegistrationChanged:(NSNotification *) sipNotification{
    BOOL isRegistered = [[[sipNotification userInfo] valueForKey:@"isRegistered"]  boolValue];
    NSInteger status = [[[sipNotification userInfo] valueForKey:@"status"]  intValue];
    
    DDLogSupport(@"REGISTER, status: %ld", (long)status);
    
    if (sipReachable != isRegistered){
        sipReachable = isRegistered;
        [self notifyReachabilityChanged];
    }
 
    // Krishna - 8/4/2014
    // Reregister when we tried to do Registration and the response is 408
    //
    // Before registration, try to shutdown the trasports. Just in case there
    // are dangling transports
    //
    if (status == 408) {
        DDLogSupport(@"Registering Timedout. Restarting the transport and registering again");
        
        // 5/5/2015 - Krishna
        // App is crashing when Registration times out in the BG
        // and the App tries to shutdown and reregister.
        //
        AppDelegate *appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
        
        if ([appDelegate isUserLoggedOut])
        {
            DDLogSupport(@"User not logged in. Do nothing.");
            return;
        }
        
        if (appDelegate.appInBackground == YES)
        {
            DDLogSupport(@"App is in BG when Registration timedout. Do nothing.");
            return;
        }

        [[QliqSip sharedQliqSip] shutdownTransport];
        [[QliqSip sharedQliqSip] setRegistered:YES];
    }
    
    if (status == 200) {
        // 9/8/2014 - Update the IP address with the latest
        // Since the registration is successful
        //
        hostIP = [self getIPAddress:YES];
        userWasRegistered |= sipReachable;
    }
}

- (void) sipMessageDeliveredNotification:(NSNotification *) notification{
    BOOL lastMessageDelivered = [[[notification userInfo] valueForKey:@"delivered"] boolValue];
    
    DDLogSupport(@"message delivery is %d",lastMessageDelivered);
    if (sipReachable != lastMessageDelivered){
        sipReachable = lastMessageDelivered;
        [self notifyReachabilityChanged];
    }
}

- (void) sipMessageReceivedNotification:(NSNotification *) notification{
    DDLogSupport(@"message received");
    if (!sipReachable){
        sipReachable = YES;
        [self notifyReachabilityChanged];
    }
}

- (void) startNotifications{
    notifyReachabilityChanges = YES;
}

- (void) stopNotifications{
    notifyReachabilityChanges = NO;
    userWasRegistered = NO;
}

- (void) startListening{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restClientReachabilityChanged:) name:RestClientReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipRegistrationChanged:) name:SIPRegistrationStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipUnregistrationEvent:) name:SIPUnregistrationStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipMessageDeliveredNotification:) name:SIPMessageDeliveredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipMessageReceivedNotification:) name:SIPMessageNotification object:nil];
}

- (void) stopListening{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RestClientReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SIPRegistrationStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SIPMessageDeliveredNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SIPMessageNotification object:nil];
}

- (NSString *) restReachabilityString{
    
	NetworkStatus temp = restReachabilityStatus;
    
	if(temp == ReachableViaWWAN){
        // updated for the fact we have CDMA phones now!
		return NSLocalizedString(@"303-ValueCellular", nil);
	}
	if (temp == ReachableViaWiFi){
		return NSLocalizedString(@"304-ValueWiFi", nil);
	}
	
	return NSLocalizedString(@"305-ValueNoConnection",nil);
}

- (BOOL) restReachable{
    return restReachabilityStatus != NotReachable;
}

- (BOOL) sipReachable{
    return sipReachable;
}

- (BOOL) isReachable{
    return [self restReachable] && [self sipReachable];
}

@end
