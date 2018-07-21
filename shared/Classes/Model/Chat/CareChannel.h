//
//  CareChannel.h
//  qliq
//
//  Created by Adam Sowa on 13/05/16.
//
//

#import "Conversation.h"

@class FhirEncounter;

@interface CareChannel : Conversation
@property (nonatomic, strong) FhirEncounter *encounter;



@end
