//
//  DeviceStatusController.h
//  qliq
//
//  Created by Aleksey Garbarev on 10/2/12.
//
//

#import <Foundation/Foundation.h>

@class DeviceStatusController;

@protocol DeviceStatusControllerDelegate <NSObject>

- (void)deviceStatusController:(DeviceStatusController *)controller performWipeWithCompletition:(CompletionBlock)complete;
- (void)deviceStatusController:(DeviceStatusController *)controller performLockWithCompletition:(CompletionBlock) complete;

@end

@interface DeviceStatusController : NSObject

@property (nonatomic, unsafe_unretained) id <DeviceStatusControllerDelegate> delegate;

//Current lock and wipe status
@property (nonatomic, readonly) NSString *lockStatus;
@property (nonatomic, readonly) NSString *wipeStatus;

- (void)refreshRemoteStatus;

- (BOOL)isLocked;

- (BOOL)isWiped;
- (void)clearWipeState;

- (void)refreshRemoteStatusWithCompletition:(CompletionBlock)complete;
- (void)loadStatusesFromKeychain;

@end
