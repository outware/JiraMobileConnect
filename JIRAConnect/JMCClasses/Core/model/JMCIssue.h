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

#import <Foundation/Foundation.h>
#import "JMCComment.h"


@interface JMCIssue : NSObject {
    NSString*_requestId;
    NSString* _key;
    NSString* _status;
    NSString* _summary;
    NSString* _description;
    NSDate* _dateUpdated;
    NSDate* _dateCreated;
    NSMutableArray* _comments;
    BOOL _hasUpdates;
}

@property (nonatomic, strong) NSDate* dateCreated;
@property (nonatomic, strong) NSDate* dateUpdated;
@property (nonatomic, weak) NSNumber* dateUpdatedLong;
@property (nonatomic, weak) NSNumber* dateCreatedLong;
@property (nonatomic, strong) NSString* requestId;
@property (nonatomic, strong) NSString* key;
@property (nonatomic, strong) NSString* status;
@property (nonatomic, strong) NSString* summary;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) NSMutableArray* comments;
@property (nonatomic, assign) BOOL hasUpdates;

- (id) initWithDictionary:(NSDictionary*)map;
- (JMCComment *) latestComment;

+(JMCIssue *)issueWith:(NSString*)issueJSON requestId:(NSString*)uuid;

@end
