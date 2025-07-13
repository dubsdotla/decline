// PreferencesWindowController.m
#import "PreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"

@implementation PreferencesWindowController
+ (instancetype)sharedController {
    static PreferencesWindowController *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 1) Create your prefs view controller
        GeneralPreferencesViewController *vc = [[GeneralPreferencesViewController alloc] init];

        // 2) Make an NSWindow with the desired size & style
        NSRect frame = NSMakeRect(0, 0, 400, 250);
        NSUInteger style = NSWindowStyleMaskTitled
        | NSWindowStyleMaskClosable;
        NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:style
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];

        // 3) Embed your VC in that window
        win.contentViewController = vc;
        win.title = @"Preferences";
        [win center];

        // 4) Finally hook it up to your NSWindowController
        shared = [[self alloc] initWithWindow:win];
    });
    return shared;
}
@end
