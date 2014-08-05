//
//  JMCConsoleLogReader.m
//  AngryNerds2
//
//  Created by Nicholas Pellow on 15/04/12.
//  Copyright (c) 2012 Nick Pellow. All rights reserved.
//

#import "JMCConsoleLogReader.h"
#import "asl.h"
#import "JMCMacros.h"

#define kJMCMaxMsgIdLastLogged @"kJMCMaxMsgIdLastLogged"

@implementation JMCConsoleLogReader


+(void) writeConsoleLogToPath:(NSString*)path forSender:(NSString*)appId
{
    #if TARGET_IPHONE_SIMULATOR
    JMCDLog(@"Can not write console log when app is run on Simulator. Must test this on a device.");
    return;
    #endif
    
    aslmsg q, m;
    int i;
    const char *key, *val;
    
    NSString* lastLoggedId = [[NSUserDefaults standardUserDefaults] objectForKey:kJMCMaxMsgIdLastLogged];
    
    const char* lastLoggedMsgId = lastLoggedId ? [lastLoggedId UTF8String] : "0";
    
    q = asl_new(ASL_TYPE_QUERY);
    asl_set_query(q, ASL_KEY_SENDER, [appId UTF8String], ASL_QUERY_OP_EQUAL);
    asl_set_query(q, ASL_KEY_MSG_ID, lastLoggedMsgId, ASL_QUERY_OP_GREATER);
    aslresponse r = asl_search(NULL, q);
    
    const char* maxMsgId = "0";
    
    NSOutputStream* outStream = [[NSOutputStream alloc] initToFileAtPath:path append:YES];
    [outStream open];
    while (NULL != (m = aslresponse_next(r)))
    {        
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)
        {
            val = asl_get(m, key);
            NSString *string = [NSString stringWithUTF8String:val];
            string = [string stringByAppendingString:@" "];
            [outStream write:[[string dataUsingEncoding:NSUTF8StringEncoding] bytes] maxLength:[string length]];
            if (strcmp(key, ASL_KEY_MSG_ID) == 0) {
                maxMsgId = val;
            }
        }

        [outStream write:[[@"\n" dataUsingEncoding:NSUTF8StringEncoding] bytes] maxLength:[@"\n" length]];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithUTF8String:maxMsgId] forKey:kJMCMaxMsgIdLastLogged];
    
    
    [outStream close];
    aslresponse_free(r);
}

@end
