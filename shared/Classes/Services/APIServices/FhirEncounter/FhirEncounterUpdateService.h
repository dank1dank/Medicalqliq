//
//  FhirEncounterUpdateService.h
//  qliq
//
//  Created by Adam Sowa on 20/07/16.
//
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface FhirEncounterUpdateService : QliqAPIService

- (id) initWithId:(NSString *)encounterId andJson:(NSString *)json;

@end
