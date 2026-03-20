#import <UIKit/UIKit.h>
#import "SideNotePanel.h"

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            [[SideNotePanel sharedInstance] setup];
        } @catch (NSException *exception) {
            NSLog(@"[SideNote] Failed to initialize: %@", exception);
        }
    });
}

%end
