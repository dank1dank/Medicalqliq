//
//  ForwardListController.m
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ForwardListController.h"
#import "DeclineOptionsTableFooterView.h"
#import "ForwardListTableViewCell.h"

@implementation ForwardListController

-(id) init
{
    self = [super init];
    if(self)
    {
        contacts = [[NSMutableArray alloc] init];
        [self refreshData];
    }
    return self;
}

-(void) dealloc
{
    [contacts release];
    [super dealloc];
}

-(void) refreshData
{
    //todo complete
}


#pragma mark -
#pragma mark UITableViewDelagate

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 12;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseId = @"forwardListTableViewCell";
    ForwardListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[ForwardListTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %ld", @"Contact", (long)indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %ld", @"Number", (long)indexPath.row];
    
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 50.0;
}

-(UIView*) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    DeclineOptionsTableFooterView *rez = [[DeclineOptionsTableFooterView alloc] init];
    rez.label.text = @"Add New Contact To Forward List";
    return [rez autorelease]; 
}

@end
