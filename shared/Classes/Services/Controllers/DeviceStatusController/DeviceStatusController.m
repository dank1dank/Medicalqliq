//
//  DeviceStatusController.m
//  qliq
//
//  Created by Aleksey Garbarev on 10/2/12.
//
//

#import "DeviceStatusController.h"

#import "UserSessionService.h"

#import "GetDeviceStatus.h"
#import "SetDeviceStatus.h"

#import "AppDelegate.h"
#import "KeychainService.h"

@interface DeviceStatusController()

@property (nonatomic, strong) NSString *wipeStatus;
@property (nonatomic, strong) NSString *lockStatus;

@end

@implementation DeviceStatusController

@synthesize delegate;

- (id)init {
    self = [super init];
    if (self){
        [self loadStatusesFromKeychain];
    }
    return self;
}

- (void)loadStatusesFromKeychain {
    self.wipeStatus = [[KeychainService sharedService] getWipeState];
    self.lockStatus = [[KeychainService sharedService] getLockState];
}

- (void)saveStatusesToKeychain {
    [[KeychainService sharedService] saveLockState:self.lockStatus];
    [[KeychainService sharedService] saveWipeState:self.wipeStatus];
}

- (void)performUpdateStatus {
    [self saveStatusesToKeychain];
    // KK 9/28/2015
    // No need to do here again. It's causing 2 times.
    // [[SetDeviceStatus sharedService] setDeviceStatusLock:self.lockStatus wipeState:self.wipeStatus onCompletion:nil];
}

/**
 Refresh statuses from server via GetDeviceStatusService, 
 then call  delegate to perform 'lock' or 'wipe' action. 
 After lock and wipe are performed - then call 'complete' block callback and 
 send current status to server via SetDeviceStatusService
 */
///
- (void)refreshRemoteStatusWithCompletition:(CompletionBlock)complete {
    DDLogSupport(@"refreshing 'DeviceStatus' from remote server..");
    
    dispatch_group_t group = dispatch_group_create();

    [[GetDeviceStatus sharedService] getDeviceStatusOnCompletion: ^(BOOL lock, BOOL wipeData) {
        
        DDLogSupport (@"Device locked = %i, data wiped = %i", lock, wipeData);
        
        NSString *locking = self.lockStatus;
        
        [self loadStatusesFromKeychain];
        
        if (lock && ![locking isEqualToString:GetDeviceStatusLocked] && ![locking isEqualToString:GetDeviceStatusLocking]) {
            DDLogSupport (@"Device must be locked");
            
            dispatch_group_enter(group);
            [delegate deviceStatusController:self performLockWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                self.lockStatus = (status == CompletitionStatusSuccess) ? GetDeviceStatusLocked : GetDeviceStatusLockFailed;
                dispatch_group_leave(group);
            }];
        }
        
        if (wipeData) {
            
            if ([self.lockStatus isEqualToString:locking]) {
                DDLogSupport (@"Device data must be wiped");
                dispatch_group_enter(group);
                [delegate deviceStatusController:self performWipeWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                    self.wipeStatus = (status == CompletitionStatusSuccess) ? GetDeviceStatusWiped : GetDeviceStatusWipeFailed;
                    dispatch_group_leave(group);
                }];
            }
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [self performUpdateStatus];
            if (complete) complete(CompletitionStatusSuccess, self, nil);
        });
        
    } onError:^(NSError *error) {
        DDLogError(@"error getting status: %@",error);
        if (complete) complete(CompletitionStatusError, self, error);
    }];
}

- (void) refreshRemoteStatus {
    [self refreshRemoteStatusWithCompletition:nil];
}

- (void) clearWipeState {
    [[KeychainService sharedService] saveWipeState:GetDeviceStatusNone];
}


#pragma mark - Accessors

- (BOOL) isLocked{
    return [self.lockStatus isEqual:GetDeviceStatusLocked] || [self.lockStatus isEqual:GetDeviceStatusLocking];
}

- (BOOL) isWiped {
    [self loadStatusesFromKeychain];
    return [self.wipeStatus isEqual:GetDeviceStatusWiped] || [self.wipeStatus isEqual:GetDeviceStatusWiping];
}

- (NSString *)lockStatus {
    return _lockStatus;
}

- (NSString *)wipeStatus{
    return _wipeStatus;
}

@end
