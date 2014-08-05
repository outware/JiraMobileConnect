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

enum {
    JMCAttachmentTypeRecording = 1,
    JMCAttachmentTypeImage = 2,
    JMCAttachmentTypePayload = 3, // use this type for any custom attachments.
    JMCAttachmentTypeCustom = 4,  // used for any custom fields
    JMCAttachmentTypeSystem = 5
};
typedef int JMCAttachmentType;

@interface JMCAttachmentItem : NSObject <NSCoding> {
    NSString* name;
    NSString*filenameFormat;
    NSString* contentType;
    JMCAttachmentType type;
    NSData* data;
    NSUInteger dataLength;
    NSString* path;
    UIImage *thumbnail;
    BOOL deleteFileWhenSent; // if true, then the file backing this attachment, will be purged
}

@property(nonatomic, strong) NSString *contentType;
@property(nonatomic, assign) NSUInteger dataLength;
@property(nonatomic, strong) NSString *path;
@property(nonatomic, assign) BOOL deleteFileWhenSent;

@property(nonatomic, strong) NSData *data;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *filenameFormat;
@property(nonatomic, strong) UIImage *thumbnail;
@property(nonatomic) JMCAttachmentType type;

- (id)initWithName:(NSString *)aName 
              data:(NSData *)aData 
              type:(JMCAttachmentType)aType 
       contentType:(NSString *)aContentType 
    filenameFormat:(NSString *)aFilenameFormat;

- (id)initWithName:(NSString *)aName 
              path:(NSString *)aPath 
        dataLength:(NSUInteger)aDataLength
              type:(JMCAttachmentType)aType
       contentType:(NSString *)aContentType 
    filenameFormat:(NSString *)aFilenameFormat;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end