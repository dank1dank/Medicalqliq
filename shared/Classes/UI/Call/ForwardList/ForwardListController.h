//
//  ForwardListController.h
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ForwardListController : NSObject <UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray *contacts;
}

-(void) refreshData;

@end
