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
#import "JMCNotifier.h"
#import "JMCIssueStore.h"
#import "JMC.h"

@implementation JMCNotifier

@synthesize view = _view;

static UIToolbar *_toolbar;
static UILabel *_label;
static UIButton *_button;
static CGRect startFrame;
static CGRect endFrame;

- (id)initWithStartFrame:(CGRect)start endFrame:(CGRect)end {
    if ((self = [super init])) {
        startFrame = start;
        endFrame = end;
        
        _toolbar = [[UIToolbar alloc] initWithFrame:startFrame];
        [_toolbar setBarStyle:UIBarStyleBlack];
        [_toolbar setTranslucent:YES];
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, endFrame.size.width, 20)];
        _label.backgroundColor = [UIColor clearColor];
#ifdef __IPHONE_6_0
        if (NSTextAlignmentFromCTTextAlignment != NULL) {
            _label.textAlignment = NSTextAlignmentCenter;
        } else {
#endif
            _label.textAlignment = UITextAlignmentCenter;
#ifdef __IPHONE_6_0
        }
#endif
        _label.textColor = [UIColor whiteColor];
        [_toolbar addSubview:_label];

        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button setFrame:endFrame];
        [_button addTarget:self action:@selector(displayNotifications:) forControlEvents:UIControlEventTouchUpInside];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notify:) name:kJMCReceivedCommentsNotification object:nil];

    }
    return self;
}

- (void)notify:(NSTimer *)timer {
    // check notifications
    if (!_view) {
        _view =  [[UIApplication sharedApplication] keyWindow];
    }
    if ([JMCIssueStore instance].newIssueCount > 0) {

        int count = [JMCIssueStore instance].newIssueCount;
        NSString *notificationFmt = count != 1 ? JMCLocalizedString(@"JMCInAppNotification-Plural", @"%d new notification%@ from developer") : 
        JMCLocalizedString(@"JMCInAppNotification-Singular", @"");
        
        if ([JMC sharedInstance].options.notificationsViaCustomView) {
            
            NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:notificationFmt, count] 
                                                                 forKey:JMCNotificationMessageReceivedMessage];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:JMCNotificationMessageReceived object:self userInfo:userInfo];
            
            return;
        }
        
        if (!_view) {
            // since there is no nice way to detect whether or not keyWindow has been setup,
            // try and display notification 4 times, before giving up. This means JMC can be configured
            // immediately on app launch.
            NSNumber* repeatCount = timer.userInfo ? timer.userInfo : [NSNumber numberWithInt:3];
            if (repeatCount.intValue <= 0) {
                JMCALog(@"In-App notification for replies can not be displayed since keyWindow was never intialised.");
                return;
            }
            [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(notify:) userInfo:[NSNumber numberWithInt:repeatCount.intValue - 1] repeats:NO];
        }
        
        _label.text = [NSString stringWithFormat:notificationFmt, count];

        [_toolbar setFrame:startFrame];
        [_view addSubview:_toolbar];

        [UIView beginAnimations:@"animateToolbar" context:nil];
        [UIView setAnimationDuration:0.4];
        [_toolbar setFrame:endFrame]; //notice this is ON screen!
        [UIView commitAnimations];

        [_view addSubview:_button];
    } else {
        // nothing to display...
    }
}

- (UIWindow *)findVisibleWindow {
    UIWindow *visibleWindow = nil;
    
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (!window.hidden && !visibleWindow) {
            visibleWindow = window;
        }
        if ([UIWindow instancesRespondToSelector:@selector(rootViewController)]) {
            if ([window rootViewController]) {
                visibleWindow = window;
                break;
            }
        }
    }
    
    return visibleWindow;
}

- (void)displayNotifications:(id)sender {
    
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    CGSize frameSize = [[UIScreen mainScreen] applicationFrame].size;
    CGRect currStartFrame = CGRectMake(startFrame.origin.x, startFrame.origin.y, frameSize.width, frameSize.height);
    CGRect currEndFrame = CGRectMake(0, 0 + statusBarFrame.size.height, frameSize.width, frameSize.height);

    if (!_viewController) {
        _viewController = [[JMC sharedInstance] issuesViewControllerWithMode:JMCViewControllerModeDefault];
    }
    
    UIWindow *window = [self findVisibleWindow];
    if ((window) && ([window respondsToSelector:@selector(rootViewController)]) && ([window rootViewController])) {
        [window.rootViewController presentViewController:_viewController animated:YES completion:nil];
    }
    else {
        [_viewController.view setFrame:currStartFrame];
        [self.view addSubview:_viewController.view];

        [UIView beginAnimations:@"animateView" context:nil];
        [UIView setAnimationDuration:0.4];
        [_viewController.view setFrame:currEndFrame]; //notice this is ON screen!
        [UIView commitAnimations];
    }

    [_button removeFromSuperview];
    [_toolbar removeFromSuperview];
}

- (void)dealloc {

    
    _viewController = nil;
    _label = nil;
    _toolbar = nil;
    _button = nil;
    
}

@end
