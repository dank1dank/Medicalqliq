//
//  PatientService.h
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"

@class Patient;

@interface PatientService : DBServiceBase

-(BOOL) savePatient:(Patient*)patient;
-(NSArray*) getPatinents;
-(Patient *) getPatientWithGuid:(NSString *) guid;
-(Patient *) getPatientWithName:(Patient *) patient;

@end
