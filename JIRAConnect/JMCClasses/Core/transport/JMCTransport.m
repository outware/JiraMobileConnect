/**
   Copyright 2011 Atlassian Software

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
**/
#import "JMCMacros.h"
#import "JMCTransport.h"
#import "JMC.h"
#import "JMCAttachmentItem.h"
#import "JMCQueueItem.h"
#import "JMCRequestQueue.h"
#import "JMCTransportOperation.h"

@implementation JMCTransport

+(NSString *)encodeCommonParameters
{
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithCapacity:2];
    [queryParams setObject:[[JMC sharedInstance] getProject] forKey:@"project"];
    [queryParams setObject:[[JMC sharedInstance] getApiKey]  forKey:@"apikey"];
    return [JMCTransport encodeParameters:queryParams];
}


- (NSMutableDictionary*)buildCommonParams:(NSString*)subject type:(NSString *)typeName
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (subject) {
        [params setObject:subject forKey:@"summary"];
    }
    NSArray *components = [[JMC sharedInstance] components];
    if (components) {
        [params setObject:components forKey:@"components"];
    }

    [params setObject:typeName forKey:@"type"];
    return params;
}

+ (void)appendPostDataToStream:(NSOutputStream*)outStream fromFile:(NSString *)file
{
	NSInputStream *inStream = [[NSInputStream alloc] initWithFileAtPath:file];
	[inStream open];
	NSUInteger bytesRead;
	while ([inStream hasBytesAvailable]) {
		
		unsigned char buffer[1024*256];
		bytesRead = [inStream read:buffer maxLength:sizeof(buffer)];
		if (bytesRead == 0) {
			break;
		}

        [outStream write:buffer maxLength:bytesRead];
	}
	[inStream close];
}

+(void)addPart:(JMCAttachmentItem*)item 
      filename:(NSString*)filename 
           key:(NSString*)key 
      boundary:(NSString*)boundary 
      toStream:(NSOutputStream*)stream
{
    NSMutableData *body = [NSMutableData dataWithCapacity:0];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", item.contentType] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

    [stream write:[body bytes] maxLength:[body length]];
    if (item.data) 
    {
        [stream write:[item.data bytes] maxLength:[item.data length]];
    }
    else
    {
        [self appendPostDataToStream:stream fromFile:item.path];
    }
    NSData* eol = [[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
    [stream write:[eol bytes] maxLength:[eol length]];
}


+(NSString*)postDataFilePathFor:(NSString*)uuid
{
    return [[[JMC sharedInstance] dataDirPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.POST-REQUEST", uuid]];
}

+(void)writeMultiPartRequest:(NSArray*)parts boundary:(NSString*)boundary toFile:(NSString*)path
{
    
    NSOutputStream* stream = [[NSOutputStream alloc] initToFileAtPath:path append:NO];
    [stream open];
    NSMutableDictionary *unique = [[NSMutableDictionary alloc] init];
    
    // Ignore for now
    NSInteger attachmentIndex = 0;
    for (u_int i = 0; i < [parts count]; i++) {
        JMCAttachmentItem *item = [parts objectAtIndex:i];
        if (item != nil && item.filenameFormat != nil) {
            
            NSString *filename = [NSString stringWithFormat:item.filenameFormat, attachmentIndex];
            NSString *key = [item.name stringByAppendingFormat:@"-%d", attachmentIndex];    
            if (item.type == JMCAttachmentTypeCustom ||
                item.type == JMCAttachmentTypeSystem) {
                // the JIRA Plugin expects all customfields to be in the 'customfields' part.
                // If this changes, plugin must change too
                [unique setValue:item forKey:item.name];
            } else {
                [self addPart:item filename:filename key:key boundary:boundary toStream:stream];
                attachmentIndex++;
            }
        }
    }

    for (NSString *key in unique) {
        JMCAttachmentItem *item = [unique valueForKey:key];
        NSString *filename = [NSString stringWithFormat:item.filenameFormat, attachmentIndex];
        
        [self addPart:item filename:filename key:item.name boundary:boundary toStream:stream];
        
        attachmentIndex++;
    }
    
    NSData* eof = [[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    [stream write:[eof bytes] maxLength:[eof length]];
    [stream close];

}

+(void)addAllAttachments:(NSArray *)allAttachments toRequest:(NSMutableURLRequest *)request boundary:(NSString *)boundary uuid:(NSString*)uuid
{

    // the path to write the POST body to before sending
    NSString* postDataFilePath = [self postDataFilePathFor:uuid];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    // if this file already exists, simply use it, else, create it and write out the POST request to it
    if (![[NSFileManager defaultManager] fileExistsAtPath:postDataFilePath])
    {
        [self writeMultiPartRequest:allAttachments boundary:boundary toFile:postDataFilePath];
        // delete all the parts from disk that can be deleted. this POST body file will now be used instead. 
        for (JMCAttachmentItem* item in allAttachments) 
        {
            if (item.deleteFileWhenSent)
            {
                [fileManager removeItemAtPath:item.path error:nil];
            }
        }
    }
    
    NSInputStream* inStream = [[NSInputStream alloc] initWithFileAtPath:postDataFilePath];
    
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:postDataFilePath error:nil];
    
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    NSString* fileSize = [fileSizeNumber stringValue];
    [request addValue:fileSize forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBodyStream:inStream];
}

- (NSString *) getType {
    return nil;
}
- (NSString *) getIssueKey {
    return nil;
}
- (NSURL *) makeUrlFor:(NSString *)issueKey {
    return nil;
}

- (NSString *)hashForConnection:(NSURLConnection *)connection {
    return [NSString stringWithFormat:@"%@", connection];
}

- (JMCTransportOperation *) requestFromItem:(JMCQueueItem *)item
{
    // Bounday for multi-part upload
    static NSString *boundary = @"JMCf06ddca8d02e6810c0a7e3e9e9086da87f07080f";

    // Get URL
    NSURL *url = [self makeUrlFor:item.originalIssueKey];
    if (!url) {
        JMCALog(@"Invalid URL made for original issue key: %@", item.originalIssueKey);
        return nil;
    }
    
    // Create request
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [request setValue:item.uuid forHTTPHeaderField:kJMCHeaderNameRequestId];
    request.timeoutInterval = 30;

    [JMCTransport addAllAttachments:item.attachments toRequest:request boundary:boundary uuid:item.uuid];

    JMCTransportOperation *operation = [JMCTransportOperation operationWithRequest:request delegate:self.delegate];
    
    return operation;
}

-(void)sayThankYou 
{
    NSString *thankyouMsg = JMCLocalizedString(@"JMCFeedbackReceived", @"Thank you message on feedback submission");
    NSString *appName = [[JMC sharedInstance] getAppName];
    NSString *projectName = appName ? appName : [[JMC sharedInstance] getProject];
    NSString *msg = [NSString stringWithFormat:thankyouMsg, projectName];

    NSString *thankyouTitle = JMCLocalizedString(@"Thank You", @"Thank you title on feedback submission");
    UIAlertView *alertView2 = [[UIAlertView alloc] initWithTitle:thankyouTitle
                                                         message:msg
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil];
    [alertView2 show];
}

- (JMCQueueItem *)qeueItemWith:(NSString *)description
                   attachments:(NSArray *)attachments
                        params:(NSMutableDictionary *)params
                      issueKey:(NSString *)issueKey
{

    // write each data part to disk with a unique filename uuid-ID
    // store metadata in an index file: uid-index. Contains: URL, parameters(key=value pairs), parts(contentType, name, filename)
    [params setObject:description forKey:@"description"];
    [params addEntriesFromDictionary:[[JMC sharedInstance] getMetaData]];

    NSString *issueJSON = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:nil error:nil] encoding:NSUTF8StringEncoding];
    NSData *jsonData = [issueJSON dataUsingEncoding:NSUTF8StringEncoding];
    JMCAttachmentItem *issueItem = [[JMCAttachmentItem alloc] initWithName:@"issue"
                                                                      data:jsonData
                                                                      type:JMCAttachmentTypeSystem
                                                               contentType:@"application/json"
                                                            filenameFormat:@"issue.json"];
    
    
    NSMutableArray *allAttachments = [NSMutableArray array];
    [allAttachments addObject:issueItem];
    
    if (attachments != nil) {
        [allAttachments addObjectsFromArray:attachments];
    }

    NSString *requestId = [JMCQueueItem generateUniqueId];

    JMCQueueItem *queueItem = [[JMCQueueItem alloc] initWith:requestId
                                                        type:[self getType]
                                                 attachments:allAttachments
                                                    issueKey:issueKey];

    [self.delegate transportWillSend:issueJSON requestId:requestId issueKey:issueKey];

    return queueItem;
}

#pragma mark end

@synthesize delegate = _delegate;



+ (CFStringRef)newEncodedValue:(CFStringRef)value {
    return CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            value,
            NULL,
            (CFStringRef) @";/?:@&=+$,",
            kCFStringEncodingUTF8);
}


+ (NSMutableString *)encodeParameters:(NSDictionary *)parameters {
    NSMutableString *params = nil;
    if (parameters != nil) {
        params = [[NSMutableString alloc] init];
        for (id key in parameters) {
            NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            CFStringRef value = (CFStringRef) CFBridgingRetain([[parameters objectForKey:key] copy]);

            // Escape even the "reserved" characters for URLs
            // as defined in http://www.ietf.org/rfc/rfc2396.txt
            CFStringRef encodedValue = [self newEncodedValue:value];

            [params appendFormat:@"%@=%@&", encodedKey, encodedValue];

            CFRelease(value);
            CFRelease(encodedValue);
        }
        [params deleteCharactersInRange:NSMakeRange([params length] - 1, 1)];
    }
    return params;

}


@end
