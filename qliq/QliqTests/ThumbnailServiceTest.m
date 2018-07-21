//
//  ThumbnailServiceTest.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/14/12.
//
//

#import "ThumbnailServiceTest.h"
#import "ThumbnailService.h"

#import "MessageAttachment.h"
#import "NSData+Base64.h"

@implementation ThumbnailServiceTest


- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void) testThumbnailFromReceivedAttachment{
    
    NSDictionary * receivedAttachmentDict = @{
    @"encryptionMethod" :  @"1",
    @"fileName" : @"_gAtspq1h7c.jpg",
    @"key" : @"7vaKb7xdHpIQv5SP/ABx4Cl5z/gCNqAsY7uDFRh3CiI=\n|fdOZ3YKJAMcIFbTnCt01mA==\n",
    @"mime" : @"image/jpeg",
    @"size" : @"46016",
    @"thumbnail" : @"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",
    @"url" : @"20121115050738"
    };
    
    MessageAttachment * attachment = [[MessageAttachment alloc] initWithDictionary:receivedAttachmentDict];
    
    NSString * base64Thumb = [receivedAttachmentDict objectForKey:@"thumbnail"];
    NSData * thumbData = [NSData dataWithBase64EncodedString:base64Thumb];
    UIImage * thumbnailImage = [UIImage imageWithData:thumbData];
    
    
    UIImage * generatedThumb = [[ThumbnailService sharedService] thumbnailForAttachment:attachment withImage:thumbnailImage];
    
    STAssertNotNil(generatedThumb, @"");
    
    UIImage * thumb = [attachment thumbnailStyled:YES];
    
    STAssertNotNil(thumb, @"Thumbnail for attachment can't be nil");
    
}


- (void) testThumbnailForSendingAttachment{
    
    
    
}

@end
