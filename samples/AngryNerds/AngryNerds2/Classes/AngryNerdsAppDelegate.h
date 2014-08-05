
#import <UIKit/UIKit.h>

#import "AngryNerdsViewController.h"

@interface AngryNerdsAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AngryNerdsViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet AngryNerdsViewController *viewController;

@end

