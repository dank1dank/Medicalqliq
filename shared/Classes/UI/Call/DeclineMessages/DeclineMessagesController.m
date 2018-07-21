//
//  DeclineMessagesController.m
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DeclineMessagesController.h"
#import "DeclineOptionsTableFooterView.h"
#import "DeclineMessageService.h"
#import "DeclineMessage.h"

@interface DeclineMessagesController()

@end

@implementation DeclineMessagesController

@synthesize delegate;
@synthesize tableView;

-(id) init
{
    self = [super init];
    if(self)
    {
        declineMessages = [[NSMutableArray alloc] init];
        declineMessageService = [[DeclineMessageService alloc] init];
        [self refreshData];
    }
    return self;
}

-(void) dealloc
{
    [tableView release];
    [declineMessageService release];
    [declineMessages release];
    [super dealloc];
}


-(void) refreshData
{
    [declineMessages removeAllObjects];
    [declineMessages addObjectsFromArray:[declineMessageService getDeclineMessages]];
}

#pragma mark -
#pragma mark UITableViewDelegate

#pragma mark -
#pragma mark UITableViewDataSource

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [declineMessages count];
}

-(UITableViewCell*) tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseId = @"DeclineMessagesReuseId";
    DeclineMessageTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[DeclineMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId] autorelease];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    DeclineMessage *message = [declineMessages objectAtIndex:indexPath.row];
    cell.textLabel.text = message.messageText;
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 50.0;
}

-(UIView*) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    DeclineOptionsTableFooterView *rez = [[DeclineOptionsTableFooterView alloc] init];
    rez.label.text = @"Create New Message";
    return [rez autorelease];
}


#pragma mark -
#pragma mark DeclineMessageTableViewCellDelegate

-(void) sendButtonPressedOnCell:(DeclineMessageTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    DeclineMessage *message = [declineMessages objectAtIndex:indexPath.row];
    [self.delegate declineMessageSelected:message];
}

@end
