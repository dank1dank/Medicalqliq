//
//  MessageTimestampViewController.m
//  qliq
//
//  Created by Valeriy Lider on 10/1/14.
//
//

#import "MessageTimestampViewController.h"

#import "ChatMessage.h"

#import "MessageStatusLog.h"
#import "MessageStatusLogDBService.h"

#import "QliqUserDBService.h"
#import "Helper.h"

#import "TimestampCell.h"
#import "ConversationTableViewCell.h"

#define kValueDefaultCellHeight   36.f
#define kValueDefaultHeaderHeight 24.f

static NSString* kMessageHistoryCell = @"TimestampCell";

typedef NS_ENUM(NSInteger, ContentType) {
    ContentTypeMesseageBubbleInfo = 0,
    ContentTypeMessageHistory
};

@interface MessageTimestampViewController(Private)

- (void)refresh;

@end

@implementation MessageTimestampViewController(Private)

- (void)refresh
{
    /*
    NSSet *set = [NSSet setWithArray:[[MessageStatusLogDBService sharedService] getMessageStatusLogForMessage:self.message] ];
    self.messageHistory = [set allObjects];
     */
    
    self.messageHistory = [[MessageStatusLogDBService sharedService] getMessageStatusLogForMessage:self.message];
}
@end

@interface MessageTimestampViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *leftButtonNavigationBarTitle;


@property (nonatomic, assign) MessageHistroryMode currentMessageHistroryMode;
@property (nonatomic, strong) QliqUser *selectedUser;

@property (nonatomic, strong) NSMutableArray *content;
@property (nonatomic, strong) NSMutableArray *messageBubbleInfo;
@property (nonatomic, strong) NSMutableArray *messageCurrentHistory;

@end

@implementation MessageTimestampViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.content = [NSMutableArray new];
    
    //TableView
    {
        self.tableView.tableFooterView = [[ UIView alloc ] initWithFrame:CGRectZero];
    }
    
    //ChatMessage
    {
        /*
        ChatMessage *newMessage = [[ChatMessage alloc] init];
        newMessage.messageId = self.message.messageId;
        newMessage.conversationId = self.message.conversationId;
        newMessage.fromQliqId = self.message.fromQliqId;
        newMessage.toQliqId = self.message.toQliqId;
        newMessage.text = self.message.text;
        newMessage.subject = self.message.subject;
        newMessage.createdAt = self.message.createdAt;
        newMessage.toUserDisplayName = self.message.toUserDisplayName;
        newMessage.toUserSipUri = self.message.toUserSipUri;
        newMessage.timestamp = self.message.timestamp;
        newMessage.metadata = self.message.metadata;
        newMessage.deliveryStatus = newMessage.deliveryStatus;
        newMessage.serverContext = self.message.serverContext;
        newMessage.hasAttachment = self.message.hasAttachment;
        newMessage.deleted = self.message.deleted;
        newMessage.deletedStatus = self.message.deletedStatus;
        newMessage.attachments = self.message.attachments;
        newMessage.recalledStatus = self.message.recalledStatus;

        self.message = newMessage;
        */
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private -

- (void)prepareContent
{
    //LefNavigationBarTitle
    {
        self.leftButtonNavigationBarTitle.text = QliqLocalizedString(@"2196-TitleMessageDetails");
    }
    
    
    //MessageBubbleInfo
    {
        if (!self.messageBubbleInfo)
            self.messageBubbleInfo = [NSMutableArray new];
        
        [self.messageBubbleInfo removeAllObjects];
        
        if (self.message)
            [self.messageBubbleInfo addObject:self.message];
    
    }
    
    //messageHistory
    {
        [self refresh];
        
        if (!self.messageCurrentHistory)
            self.messageCurrentHistory = [NSMutableArray new];
        
        [self.messageCurrentHistory removeAllObjects];
        
        switch (self.currentMessageHistroryMode)
        {
            case MessageHistroryModeAllHistory: {
                
                self.selectedUser = nil;
                
                if (self.isGroupMessage)
                {
                    NSMutableArray *array = [NSMutableArray new];
                    NSMutableDictionary *dictLogsWithQliqId = [NSMutableDictionary new];
                    
                    for (MessageStatusLog *messageLog in self.messageHistory)
                    {
                        if (!messageLog.timestamp)
                            messageLog.timestamp = 0.f;
                        
                        if (messageLog.qliqId)
                        {
                            MessageStatusLog *messageLogOld = [dictLogsWithQliqId objectForKey:messageLog.qliqId];
                            
                            if (messageLogOld)
                            {
                                if(messageLog.timestamp > messageLogOld.timestamp)
                                    [dictLogsWithQliqId setObject:messageLog forKey:messageLog.qliqId];
                            }
                            else
                                [dictLogsWithQliqId setObject:messageLog forKey:messageLog.qliqId];
                        }
                        else
                            [array addObject:messageLog];
                    }
                    
                    NSArray *arrayDictLogsWithQliqId = [NSArray new];
                    arrayDictLogsWithQliqId = [dictLogsWithQliqId allValues];
                    
                    array = [[array arrayByAddingObjectsFromArray:arrayDictLogsWithQliqId ] mutableCopy];                    
                    array = [[array sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]] mutableCopy];
                    
                    self.messageCurrentHistory = array;
                }
                else
                {
                    self.messageCurrentHistory = [[self.messageHistory sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]] mutableCopy];
                }
                
                break;
            }
            case MessageHistroryModeHostryForQliqId: {
                
                NSArray *array = [self.messageHistory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"qliqId = %@", self.selectedUser.qliqId]];
                self.messageCurrentHistory = [[array sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]] mutableCopy];
                
                break;
            }
            default: break;
        }
    }
}

#pragma mark - IBActions -

- (IBAction)onBack:(id)sender
{
    switch (self.currentMessageHistroryMode)
    {
        case MessageHistroryModeHostryForQliqId: {
            self.currentMessageHistroryMode = MessageHistroryModeAllHistory;
            [self.tableView reloadData];
            break;
        }
        case MessageHistroryModeAllHistory:
        default: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}


#pragma mark - Delegates -

#pragma mark * UITabelView Delegate/DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    {
        [self prepareContent];
        
        [self.content removeAllObjects];
        
        if (self.messageBubbleInfo.count > 0)
            [self.content addObject:@(ContentTypeMesseageBubbleInfo)];

        if (self.messageCurrentHistory.count > 0)
            [self.content addObject:@(ContentTypeMessageHistory)];
        
        count = self.content.count;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    {
        NSInteger contentType = [[self.content objectAtIndex:section] integerValue];
        
        switch (contentType)
        {
            case ContentTypeMesseageBubbleInfo: count = self.messageBubbleInfo.count;       break;
            case ContentTypeMessageHistory:     count = self.messageCurrentHistory.count;   break;
            default: break;
        }
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = kValueDefaultCellHeight;
    {
        NSInteger contentType = [[self.content objectAtIndex:indexPath.section] integerValue];
        
        switch (contentType)
        {
            case ContentTypeMesseageBubbleInfo:
                cellHeight = [ConversationTableViewCell getCellHeightWithMessage:self.message withBounds:self.tableView.bounds itsForMessageTimestamp:YES];
                break;
            case ContentTypeMessageHistory:     cellHeight = kValueDefaultCellHeight;   break;
            default: break;
        }
    }
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    {
        NSInteger contentType = [[self.content objectAtIndex:section] integerValue];
        
        switch (contentType)
        {
            case ContentTypeMesseageBubbleInfo: height = 0;   break;
            case ContentTypeMessageHistory:     height = kValueDefaultHeaderHeight;   break;
            default: break;
        }
    }
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;

    NSInteger contentType = [[self.content objectAtIndex:section] integerValue];
    
    switch (contentType)
    {
        case ContentTypeMesseageBubbleInfo:    break;
        case ContentTypeMessageHistory: {
            
            headerView = [[UIView alloc] init];
            headerView.backgroundColor = RGBa(103, 103, 103, 1.0f);
            
            //Add Content HeaderView
            {
                NSString *titleHeader      = @"";
                NSString *description      = @"";
                NSString *fullHeaderTittle = @"";
                
                switch (self.currentMessageHistroryMode)
                {
                    case MessageHistroryModeAllHistory: {
                        
                        titleHeader      = QliqLocalizedString(@"2197-TitleMessageID:");
                        description      = self.message.metadata.uuid;
                        fullHeaderTittle = [NSString stringWithFormat:@"%@ %@", titleHeader, description];
                        break;
                    }
                    case MessageHistroryModeHostryForQliqId: {
                        
                        if (self.selectedUser)
                            titleHeader = [self.selectedUser nameDescription];
                        
                        fullHeaderTittle = titleHeader;
                        
                        break;
                    }
                    default: break;
                }
                
                UIFont *titleHeaderFont    = [UIFont systemFontOfSize:14.f];
                UIFont *descriptionFont    = [UIFont systemFontOfSize:16.f];
                CGFloat offset             = 20.f;
                
                
                UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(offset/2, 0, tableView.bounds.size.width - offset, kValueDefaultHeaderHeight)];
                headerLabel.text            = fullHeaderTittle;
                headerLabel.textColor       = [UIColor whiteColor];
                headerLabel.backgroundColor = [UIColor clearColor];
                headerLabel.font            = titleHeaderFont;
                headerLabel.adjustsFontSizeToFitWidth = YES;
                
                NSRange range = NSMakeRange( [titleHeader length], [fullHeaderTittle length] - [titleHeader length]);
                NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:headerLabel.attributedText];
                [attributeString addAttribute:NSFontAttributeName value:descriptionFont range:range];
                
                
                headerLabel.attributedText  = attributeString;
                
                [headerLabel setMinimumScaleFactor:8.f/[UIFont labelFontSize]];
                
                
                [headerView addSubview:headerLabel];
            }
            
            break;
        }
        default: break;
    }
    
    
    return headerView;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger contentType = [[self.content objectAtIndex:indexPath.section] integerValue];
    
    
    switch (contentType)
    {
        case ContentTypeMesseageBubbleInfo: {

            ConversationTableViewCell *cell = nil;
            
            id object = self.messageBubbleInfo[indexPath.row];
            ChatMessage *message = object;
            
            if ([message isMyMessage])
            {
                if (!message.hasAttachment) {
                    
                    static NSString *cellIdentifier = @"ConversationMyCellReuseId";
                    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if(!cell) {
                        UINib *nib = [UINib nibWithNibName:@"ConversationMyCell" bundle:nil];
                        
                        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                        
                        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    }
                }
                else {
                    
                    static NSString *cellIdentifier = @"ConversationWithAttachmentMyCellReuseId";
                    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if(!cell) {
                        UINib *nib = [UINib nibWithNibName:@"ConversationWithAttachmentMyCell" bundle:nil];
                        
                        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                        
                        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    }
                }
            }
            else
            {
                if (!message.hasAttachment) {
                    static NSString *cellIdentifier = @"ConversationContactCellReuseId";
                    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if(!cell) {
                        UINib *nib = [UINib nibWithNibName:@"ConversationContactCell" bundle:nil];
                        
                        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                        
                        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    }
                }
                else {
                    static NSString *cellIdentifier = @"ConversationWithAttachmentContactCellReuseId";
                    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    
                    if(!cell) {
                        UINib *nib = [UINib nibWithNibName:@"ConversationWithAttachmentContactCell" bundle:nil];
                        
                        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
                        
                        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    }
                }
            }
            
            cell.backgroundColor = RGBa(224, 224, 224, 1);
            cell.userInteractionEnabled = NO;
            
            //SetCellSettings
            [cell setCellMessage:message ofUser:[message isMyMessage] isGroupConversation:self.isGroupMessage broadcastType:nil itsForMessageTimestamp:YES];
            [cell showDeletingMode:NO messageIsChecked:NO];
            
            return cell;
            break;
        }
        default:
        case ContentTypeMessageHistory: {
        
            TimestampCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageHistoryCell];
            
            if(!cell) {
                cell = [[TimestampCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kMessageHistoryCell];
            }
            
            MessageStatusLog *messageLog = [self.messageCurrentHistory objectAtIndex:indexPath.row];
            
            BOOL isGroupMessage = self.isGroupMessage;
            if (self.currentMessageHistroryMode == MessageHistroryModeHostryForQliqId)
                isGroupMessage = NO;
            
            [cell setCellWithMessage:self.message withMessageStatusLog:messageLog isGroupMessage:isGroupMessage whithSelectedQliqUser:self.selectedUser];

            return cell;
            
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isGroupMessage && self.currentMessageHistroryMode == MessageHistroryModeAllHistory)
    {
        NSInteger contentType = [[self.content objectAtIndex:indexPath.section] integerValue];

        if(contentType == ContentTypeMessageHistory)
        {
            MessageStatusLog *messageLog = [self.messageCurrentHistory objectAtIndex:indexPath.row];
            if (messageLog.qliqId)
            {
                self.selectedUser = [[QliqUserDBService sharedService] getUserWithId:messageLog.qliqId];
                self.currentMessageHistroryMode = MessageHistroryModeHostryForQliqId;
                [self.tableView reloadData];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

@end
