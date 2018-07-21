//
//  QliqCareModule.m
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqCareModule.h"
#import "QliqModuleBase+Protected.h"
#import "QliqFacilityMapMessage.h"
#import "GetFacilityMapResponseSchema.h"
#import "DBHelperNurse.h"
#import "DBUtil.h"

@interface QliqCareModule()

-(void) processFacilityMapMessage:(QliqFacilityMapMessage*)message;

@end

@implementation QliqCareModule

-(id) init
{
    self = [super init];
    if(self)
    {
        self.name = QliqCareModuleName;
        /*
        NSString *qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqCare-schema" ofType:@"sql"];
        [[DBUtil instance] loadSchema:qliqSchemaPath];
		 */
    }
    return self;
}

-(UIImage *) moduleLogo
{
    return [UIImage imageNamed:@"qliqCare_logo.png"];
}


#pragma mark -
#pragma mark Private

-(BOOL) handleSipMessage:(QliqSipMessage *)message
{
    if ([message.command compare:GET_FACILITY_MAP_RESPONSE_MESSAGE_COMMAND_PATTERN] == NSOrderedSame &&
        [message.subject compare:GET_FACILITY_MAP_RESPONSE_MESSAGE_SUBJECT_PATTERN] == NSOrderedSame)
    {
        QliqFacilityMapMessage *facilityMessage = (QliqFacilityMapMessage*)message;
        [self processFacilityMapMessage:facilityMessage];
        return YES;
    }
    return NO;
}


#pragma mark -
#pragma mark Private

-(void) processFacilityMapMessage:(QliqFacilityMapMessage *)message
{
    // Delete old floor map
    [DBHelperNurse deleteFloorsAndRooms];
    
    for (NSDictionary *facility in message.dataArray)
    {
        //        NSString *facilityName = [facility objectForKey:GET_FACILITY_MAP_RESPONSE_DATA_FACILITY_NAME];
        NSString *facilityNpi = [facility objectForKey:GET_FACILITY_MAP_RESPONSE_DATA_FACILITY_NPI];
        NSArray *buildings = [facility objectForKey:GET_FACILITY_MAP_RESPONSE_DATA_BUILDINGS];
        
        for (NSDictionary *building in buildings)
        {
            //            NSString *buildingName = [building objectForKey:GET_FACILITY_MAP_RESPONSE_BUILDINGS_NAME];
            NSArray *floors = [building objectForKey:GET_FACILITY_MAP_RESPONSE_BUILDINGS_FLOORS];
            
            for (NSDictionary *floor in floors)
            {
                NSString *floorName = [floor objectForKey:GET_FACILITY_MAP_RESPONSE_FLOORS_NAME];
                NSArray *rooms = [floor objectForKey:GET_FACILITY_MAP_RESPONSE_FLOORS_ROOMS];
                
                Floor_old *floorObj = [[Floor_old alloc] initWithPrimaryKey:0];
                floorObj.name = floorName;
                floorObj.facilityNpi = facilityNpi;
                NSInteger floorId = [DBHelperNurse addFloor:floorObj];
                
                for (NSDictionary *room in rooms)
                {
                    NSString *roomName = [room objectForKey:GET_FACILITY_MAP_RESPONSE_ROOMS_NAME];
                    NSNumber *maxOccNumber = [room objectForKey:GET_FACILITY_MAP_RESPONSE_ROOMS_MAX_OCC];
                    Room *roomObj = [[Room alloc] initWithPrimaryKey:0];
                    roomObj.room = roomName;
                    roomObj.floorId = floorId;
                    
                    if (maxOccNumber)
                        roomObj.numberOfBeds = [maxOccNumber intValue];
                    
                    [DBHelperNurse addRoom:floorId :roomObj];
                    [roomObj release];
                }
                
                [floorObj release];
            }
        }
        
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FacilityInfoNotification object:nil];
}

@end
