//
//  VoiceCallsController.m
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VoiceCallsController.h"
#import "Call.h"
#import "QliqSip.h"
#import "CallInitiationResult.h"
#import "QliqUserNotifications.h"
#import "QliqUser.h"
#import "SipContactDBService.h"
#import <pjsip-ua/sip_inv.h>

@interface VoiceCallsController()

-(Call*) callWithId:(int)call_id;
-(NSString*) stringForReasonCode:(SipReasonCode)reasonCode;


@end

@implementation VoiceCallsController

@synthesize voiceCallsDelegate;

-(id) init
{
    self = [super init];
    if(self)
    {
        calls = [[NSMutableArray alloc] init];
        busy = NO;
    }
    return self;
}

-(void) dealloc
{
    [calls release];
    [super dealloc];
}


-(void) callUser:(Contact *)userContact
{
    Call *outgoingCall = [[Call alloc] init];
    outgoingCall.type = CallTypeOutgoing;
	outgoingCall.contact = userContact;
	outgoingCall.state = CallStateInitial;
 
    SipContactDBService * sipContactService = [[[SipContactDBService alloc] init] autorelease];
    SipContact *toContact = [sipContactService sipContactForQliqId:[(QliqUser*)userContact qliqId]];
    
    [self.voiceCallsDelegate initiatingCall:outgoingCall];

    if (![voiceCallsDelegate isReachable])
    {
        DDLogSupport(@"*** CallUser failed. Network error");
        [self.voiceCallsDelegate callFailedWithReason:[self stringForReasonCode:491]];
        [outgoingCall release];
        return;
    }
    if (![[QliqSip instance] isRegistered])
    {
        DDLogSupport(@"*** CallUser failed. Server error");
        [self.voiceCallsDelegate callFailedWithReason:[self stringForReasonCode:503]];
        [outgoingCall release];        
        return;
    }
    
    CallInitiationResult *rez = [[QliqSip instance] makeCall:toContact.qliqId];
    if(rez.call_id == -1)
    {
        //TODO handle error
        //rez.error
    }
    else
    {
        outgoingCall.call_id = rez.call_id;
        [calls addObject:outgoingCall];
        busy = YES;
    }
    [outgoingCall release];
}

-(void) callStateChanged:(CallStateChangeInfo *)stateChangeInfo
{
    int callId = [stateChangeInfo.call_id intValue];
    
    Call *call = [self callWithId:callId];
    
    pjsip_inv_state state = [stateChangeInfo.state intValue];
    
    if(call == nil)
    {
        DDLogSupport(@"*** stack state change received but there is no call. state: %d", state);
        return;
    }

    
    switch (state)
    {
        case PJSIP_INV_STATE_CALLING:
        {
            DDLogSupport(@"*** stack state changed to: CALLING. Call State: %@", [call stringForCallState]);
            if(call.state != CallStateEstablishing)
            {
                call.state = CallStateEstablishing;

            }
        }break;
            
        case PJSIP_INV_STATE_CONFIRMED:
        {
            DDLogSupport(@"*** stack state changed to: CONFIRMED. . Call State: %@", [call stringForCallState]);
            call.state = CallStateInProgress;
            //notify delegate call start;
            if(call.type == CallTypeIncoming)
            {
                [[QliqSip instance] stop_ring];
            }
            else 
            {
                [[QliqSip instance] stop_ringback];
            }
            [self.voiceCallsDelegate callStarted];
        }break;
            
        case PJSIP_INV_STATE_CONNECTING:
        {
            DDLogSupport(@"*** stack state changed to: CONNECTING. . Call State: %@", [call stringForCallState]);
            if(call.type == CallTypeIncoming)
            {
                //notify delegate call start;
                [[QliqSip instance] stop_ring];
            }
            call.state = CallStateInProgress;
            [self.voiceCallsDelegate callStarted];
        }break;
            
        case PJSIP_INV_STATE_EARLY:
        {
            DDLogSupport(@"*** stack state changed to: EARLY MEDIA. . Call State: %@", [call stringForCallState]);
            if(call.type == CallTypeOutgoing)
            {
                [[QliqSip instance] start_ringback];
                call.state = CallStateAccepted;
            }    
            break;
        }
            
        case PJSIP_INV_STATE_DISCONNECTED:
        {
            DDLogSupport(@"*** stack state changed to: DISCONNECTED. . Call State: %@", [call stringForCallState]);
            if(call.type == CallTypeIncoming)
            {
                [[QliqSip instance] stop_ring];
                //incoming call ended
                [self.voiceCallsDelegate callEnded];
            }
            else if(call.type == CallTypeOutgoing)
            {
                if(call.state == CallStateInProgress)
                {
                    [self.voiceCallsDelegate callEnded];
                }
                if(call.state == CallStateEstablishing || call.state == CallStateAccepted)
                {
                    //outgoing call declined;
                    [self.voiceCallsDelegate callFailedWithReason:[self stringForReasonCode:[stateChangeInfo.lastReasonCode intValue]]];
                }
                [[QliqSip instance] stop_ringback];
            }
            busy = NO;
            [calls removeObject:call];
                    }break;
            
        default:
            DDLogSupport(@"*** Unhandled stack state changed %d. Call State: %@", state, [call stringForCallState]);
            break;
    }
}

-(void) incomingCall:(NSNumber *)call_id
{
    if(busy)
    {
        DDLogSupport(@"*** Incoming call: busy");
        [[QliqSip instance] declineCall:[call_id intValue] reasonCode:SipReasonCodeBusyHere];
    }
    else
    {
        Call *incomingCall = [[Call alloc] init];
        incomingCall.type = CallTypeIncoming;
        incomingCall.state = CallStatePresented;
        incomingCall.call_id = [call_id intValue];
        incomingCall.contact = [QliqSip contactForCallId:call_id];
        [calls addObject:incomingCall];
        //notify delegate incoming call
        [[QliqUserNotifications getInstance] notifyIncomingCall:incomingCall];
        [self.voiceCallsDelegate incomingCall:incomingCall];
        [incomingCall release];
        
        [[QliqSip instance] start_ring:[call_id intValue]];
    }
}

-(void) answerCall:(Call *)call
{
    DDLogSupport(@"*** answerCall. Call State: %@", [call stringForCallState]);
    QliqSip *instance = [QliqSip instance];
    [instance answerCall:call.call_id];
}

-(void) endCall:(Call *)call
{
    DDLogSupport(@"*** endCall. Call State: %@", [call stringForCallState]);
//    [calls removeObject:call];
    QliqSip *instance = [QliqSip instance];
//    if(call.state == CallStateInProgress)
//    {
//        [instance muteMicForCallWithId:call.call_id];
//    }
    [instance endCall: call.call_id];
    [self.voiceCallsDelegate callEnded];
    [instance stop_ring];
    [instance stop_ringback];
    busy = NO;
}

-(void) declineCall:(Call *)call
{
    DDLogSupport(@"*** declineCall. Call State: %@", [call stringForCallState]);
    [calls removeObject:call];
    QliqSip *instance = [QliqSip instance];
    [instance declineCall:call.call_id reasonCode:SipReasonCodeDecline];
    [instance stop_ring];
}

#pragma mark -
#pragma mark Private

-(Call*) callWithId:(int)call_id
{
    Call *rez = nil;
    for(Call* call in calls)
    {
        if(call.call_id == call_id)
        {
            rez = call;
            break;
        }
    }
    return rez;
}

-(NSString*)stringForReasonCode:(SipReasonCode)reasonCode
{
    NSString *rez = nil;
    switch (reasonCode)
    {
        case SipReasonCodeBusyHere:
        {
            rez = @"Busy";
        }break;
        case SipReasonCodeDecline:
        {
            rez = @"Declined";
        }
            break;
        case SipReasonNetworkError:
        {
            rez = @"Network error";
        } break;
        default:
            break;
    }
    
    if(rez == nil)
    {
        rez = @"Call Failed";
    }
    
    return rez;
}



@end
