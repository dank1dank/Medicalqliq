//
//  FacilityViewController.h
//  qliq
//
//  Created by Paul Bar on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "FacilityView.h"

@class Facility;

@interface FacilityViewController : QliqBaseViewController
{
    Facility *facility;
}

-(id) initWithFacility:(Facility*)facility;

@end
