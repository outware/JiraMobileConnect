//
//  JMCConsoleLogReader.h
//  AngryNerds2
//
//  Created by Nicholas Pellow on 15/04/12.
//  Copyright (c) 2012 Nick Pellow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMCConsoleLogReader : NSObject

+(void) writeConsoleLogToPath:(NSString*)path forSender:(NSString*)appId;

@end
