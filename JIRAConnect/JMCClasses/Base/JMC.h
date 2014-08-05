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
#import "JMCViewController.h"
#import "CrashReporter.h"
#import "JMCAttachmentItem.h"
#import "JMCMacros.h"

@class JMCIssuesViewController, JMCPing, JMCNotifier, JMCNotifier, JMCCrashSender;

// Use this macro outside JMC to enable code that depends on JMC
#define JMC_PRESENT
// the name of the actual notification to be posted when a message is received from a developer
#define JMCNotificationMessageReceived @"JMCNotificationMessageReceived" 
// the key for the message in the user info dict
#define JMCNotificationMessageReceivedMessage @"JMCNotificationMessageReceivedMessage" 

// Constants
#define kJIRAConnectUUID @"kJIRAConnectUUID"
#define kJMCReceivedCommentsNotification @"kJMCReceivedCommentsNotification"
#define kJMCLastSuccessfulPingTime @"kJMCLastSuccessfulPingTime"
#define kJMCIssueUpdated @"kJMCIssueUpdated"
#define kJMCNewCommentCreated @"kJMCNewCommentCreated"

#define kJMCOptionUrl @"kJMCOptionUrl"
#define kJMCOptionProjectKey @"kJMCOptionProjectKey"
#define kJMCOptionApiKey @"kJMCOptionApiKey"
#define kJMCOptionPhotosEnabled @"kJMCOptionPhotosEnabled"
#define kJMCOptionVoiceEnabled @"kJMCOptionVoiceEnabled"
#define kJMCOptionLocationEnabled @"kJMCOptionLocationEnabled"
#define kJMCOptionCrashReportingEnabled @"kJMCOptionCrashReportingEnabled"
#define kJMCOptionNotificationsEnabled @"kJMCOptionNotificationsEnabled"
#define kJMCOptionNotificationsViaCustomView @"kJMCOptionNotificationsViaCustomView"
#define kJMCOptionCustomFields @"kJMCOptionCustomFields"
#define kJMCOptionUIBarStyle @"kJMCOptionUIBarStyle"
#define kJMCOptionUIModalPresentationStyle @"kJMCOptionUIModalPresentationStyle"
#define kJMCOptionConsoleLogEnabled @"kJMCOptionConsoleLogEnabled"

@interface JMCOptions : NSObject {
    NSString* _url;
    NSString* _projectKey;
    NSString* _apiKey;
    BOOL _photosEnabled;
    BOOL _voiceEnabled;
    BOOL _locationEnabled;
    BOOL _crashReportingEnabled;
    BOOL _notificationsEnabled;
    BOOL _notificationsViaCustomView;
    BOOL _consoleLogEnabled;
    NSDictionary* _customFields;
    UIBarStyle _barStyle;
    UIColor* _barTintColor;
    UIModalPresentationStyle _modalPresentationStyle;
}

+(id) optionsWithContentsOfFile:(NSString *)filePath;
+(id) optionsWithUrl:(NSString *)jiraUrl
            projectKey:(NSString*)projectKey
             apiKey:(NSString*)apiKey
             photos:(BOOL)photos
              voice:(BOOL)voice
           location:(BOOL)location
       crashReporting:(BOOL)crashreporting
       notifications:(BOOL)notifications
       customFields:(NSDictionary*)customFields;

/**
* The base URL of the JIRA instance.
* e.g. http://connect.onjira.com
*/
@property (strong, nonatomic) NSString* url;

/**
* If non-nil, use this project name when creating feedback. Otherwise, the bundle name is used.
* This value can be either the JIRA Project's name, _or_ its Project Key. e.g. CONNECT
*/
@property (strong) NSString* projectKey;

/**
* This is required to talk to JIRA.
* A API Key exists per JIRA project. see also http://developer.atlassian.com/x/J4VW
*/
@property (strong) NSString* apiKey;

/**
 * If YES users will be able to submit screenshots/photos with their feedback, this is YES by default.
 */
@property (assign) BOOL photosEnabled;

/**
 * If YES users will be able to submit voice recordings with their feedback, this is YES by default.
 */
@property (assign) BOOL voiceEnabled;

/**
 * If YES the location data (lat/lng) will be sent as a part of the issue, this is NO by default.
 */
@property (assign) BOOL locationEnabled;

/**
 * If YES, Crash Reports will be submitted directly to JIRA. Set this to NO if you don't wish to collect crash reports
 * or are collecting Crash Reports via some other means.
 */
@property (assign) BOOL crashReportingEnabled;


/**
 * If YES, once a user has left some feedback or reported a crash, then JMC will display an In-App notification
 * whenever a developer comments on an issue in JIRA. If NO, notifications will not appear.
 */
@property (assign) BOOL notificationsEnabled;

/**
 * If YES, when a notification from a developer is received, a JMCNotificationMessageReceived notification will be posted.
 * The user dict will contain the message, keyed by JMCNotificationMessageReceivedMessage.
 */
@property (assign) BOOL notificationsViaCustomView;


/**
 * If YES, then the console.log for your application will be submitted with each feedback and crash report.
 * Default is NO.
 * NB: This option is currently still in beta. Your mileage may vary.
 */
@property (assign) BOOL consoleLogEnabled;

/**
* A dicitonary mapping custom field names to custom field values.
* If the JIRA instance contains a custom field of the same name, then the value will be used
* when creating any issues.
*/
@property (strong) NSDictionary* customFields;

/**
 * The style to use for all navigation bars.
 */
@property (assign) UIBarStyle barStyle;


/**
 * The color to use for all navigation bars.
 */
@property (strong) UIColor* barTintColor;

/**
 * The presentation styles of the modal view controllers.
 */
@property (assign) UIModalPresentationStyle modalPresentationStyle;


@end

@interface JMC : NSObject {
    @private
    NSURL* __weak _url;
    JMCPing *_pinger;
    JMCNotifier *_notifier;
    JMCCrashSender *_crashSender;
    id <JMCCustomDataSource> __weak _customDataSource;
    JMCOptions* _options;
}

enum JMCViewControllerMode {
  JMCViewControllerModeDefault,
  JMCViewControllerModeCustom
};

@property (nonatomic, weak) id <JMCCustomDataSource> customDataSource;
@property (nonatomic, strong) JMCOptions* options;
@property (weak, readonly) NSURL* url;

+ (JMC *)sharedInstance;

/**
* This method setups JIRAConnect for a specific JIRA instance.
* Call this method from your AppDelelegate during the application:didFinishLaunchingWithOptions method.
* If custom data is required to be attached to each crash and issue report, then provide a JMCCustomDatSource. If
* no custom data is required, then pass in nil.
*/
- (void) configureJiraConnect:(NSString*) withUrl customDataSource:(id<JMCCustomDataSource>)customDataSource;
- (void) configureJiraConnect:(NSString*) withUrl projectKey:(NSString*)project apiKey:(NSString *)apiKey;
- (void) configureJiraConnect:(NSString*) withUrl
                   projectKey:(NSString*) project
                       apiKey:(NSString *)apiKey
                   dataSource:(id<JMCCustomDataSource>)customDataSource;
- (void) configureJiraConnect:(NSString*) withUrl
                   projectKey:(NSString*) project
                       apiKey:(NSString *)apiKey
                     location:(BOOL) locationEnabled
                   dataSource:(id<JMCCustomDataSource>)customDataSource;

- (void) configureWithOptions:(JMCOptions*)options;
- (void) configureWithOptions:(JMCOptions*)options dataSource:(id<JMCCustomDataSource>)customDataSource;

/**
 * This method should not be called if any of the configureXXX methods above are called.
 * Only call start if none of the configureXXX methods were called.
 */
-(void) start;
-(void) flushRequestQueue;

/**
 * Call this method to manually trigger a ping and fetch comments.
 */
-(void) ping;

/**
* Retrieves the 'correct' viewController to present to the user.
*  * If the user has previously created feedback, the inbox is returned.
*  * If the user has not yet left any feedback, the feedbackViewController is returned.
*/
- (UIViewController*) viewController;
- (UIViewController*) viewControllerWithMode:(enum JMCViewControllerMode)mode;

/**
* Retrieves the feedback viewController for JIRAConnect. This controller holds the 'create issue' view.
*/
- (UIViewController*) feedbackViewController;
- (UIViewController*) feedbackViewControllerWithMode:(enum JMCViewControllerMode)mode;

/**
* The view controller which displays the list of all issues a user has raised for this app.
*/
- (UIViewController*) issuesViewController;
- (UIViewController*) issuesViewControllerWithMode:(enum JMCViewControllerMode)mode;

/**
 * This is a generic icon that can be used in your App as the icon for Feedback.
 */
-(UIImage*) feedbackIcon;

- (NSDictionary*) getMetaData;
- (NSMutableDictionary*) getCustomFields;
- (NSArray *) components;
- (NSString *) getProject;
- (NSString *) getApiKey;
- (NSString *) getAppName;
- (NSString *) getUUID;
- (NSString *) getAPIVersion;
- (UIBarStyle) getBarStyle;

- (BOOL) isPhotosEnabled;
- (BOOL) isVoiceEnabled;
- (BOOL) isLocationEnabled;
- (NSString*) issueTypeNameFor:(JMCIssueType)type useDefault:(NSString *)defaultType;

/** The path that JMC uses to store its data: local DB cache, and offline request queue. **/
- (NSString *)dataDirPath;

/** Determines whether or not crash reporting is enabled based on: 
    * the JMCOption.crashReportingEnabled
 **/
-(BOOL) crashReportingIsEnabled;

@end
