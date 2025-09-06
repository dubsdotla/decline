// PreferencesWindowController.m
#import "PreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"
#import "NotificationsPreferencesViewController.h"
#import "AppDelegate.h"

static NSString * const kPrefsToolbarID          = @"la.dubs.decline.preferences.toolbar";
static NSString * const kPaneIDGeneral           = @"general";
static NSString * const kPaneIDNotifications     = @"notifications";
static NSString * const kLastSelectedPaneDefaultsKey = @"prefs.lastSelectedPane";

@interface PreferencesWindowController ()
@property (nonatomic, strong) NSToolbar *toolbar;
@property (nonatomic, strong) NSDictionary<NSString *, NSViewController *> *panes;
@property (nonatomic, copy)   NSString *currentPaneID;
@end

@implementation PreferencesWindowController

+ (instancetype)sharedController {
    static PreferencesWindowController *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Create the window itself
        NSWindow *win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 250)
                                                    styleMask:(NSWindowStyleMaskTitled
                                                               | NSWindowStyleMaskClosable
                                                               | NSWindowStyleMaskMiniaturizable)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
        if (@available(macOS 11.0, *)) {
            win.toolbarStyle = NSWindowToolbarStylePreference;   // <<< gives the pill look
            win.titlebarSeparatorStyle = NSTitlebarSeparatorStyleAutomatic; // remove hairline
        }
        win.releasedWhenClosed = NO;
        win.animationBehavior = NSWindowAnimationBehaviorDocumentWindow;

        shared = [[self alloc] initWithWindow:win];
        [shared setupToolbarAndPanes];
        [shared centerInitial];
    });
    return shared;
}

- (void)setupToolbarAndPanes {
    // Build panes
    GeneralPreferencesViewController *generalVC = [[GeneralPreferencesViewController alloc] init];
    NotificationsPreferencesViewController *notifVC = [[NotificationsPreferencesViewController alloc] init];

    self.panes = @{
        kPaneIDGeneral: generalVC,
        kPaneIDNotifications: notifVC,
    };

    // Toolbar
    self.toolbar = [[NSToolbar alloc] initWithIdentifier:kPrefsToolbarID];
    self.toolbar.delegate = self;
    self.toolbar.allowsUserCustomization = NO;
    self.toolbar.autosavesConfiguration  = NO;
    self.toolbar.displayMode = NSToolbarDisplayModeIconAndLabel; // classic Xcode-like look
    self.toolbar.sizeMode    = NSToolbarSizeModeDefault;
    self.window.toolbar      = self.toolbar;

    // Select last pane or default to General
    NSString *last = [defaults stringForKey:kLastSelectedPaneDefaultsKey] ?: kPaneIDGeneral;
    [self switchToPane:last animate:NO];
    [self.toolbar setSelectedItemIdentifier:last];
}

- (void)centerInitial {
    [self.window center];
}

#pragma mark - Public API

- (void)showGeneralPane {
    [self showWindow:nil];
    [self.toolbar setSelectedItemIdentifier:kPaneIDGeneral];
    [self switchToPane:kPaneIDGeneral animate:YES];
}

#pragma mark - Switching

- (void)switchToPane:(NSString *)paneID animate:(BOOL)animate {
    NSViewController *vc = self.panes[paneID];
    if (!vc) return;

    // Make sure the view exists and is laid out so preferredContentSize is meaningful
    (void)vc.view;
    [vc.view layoutSubtreeIfNeeded];

    NSSize target = vc.preferredContentSize;
    if (NSEqualSizes(target, NSZeroSize)) {
        // Fallbacks if the VC hasn't reported one yet
        target = vc.view.translatesAutoresizingMaskIntoConstraints ? vc.view.bounds.size : vc.view.fittingSize;
        if (NSEqualSizes(target, NSZeroSize)) target = NSMakeSize(350, 250);
    }

    NSRect contentRect = NSMakeRect(0, 0, target.width, target.height);
    NSRect newFrame    = [self.window frameRectForContentRect:contentRect];

    // Keep top edge fixed
    NSRect cur = self.window.frame;
    newFrame.origin.x = cur.origin.x;
    newFrame.origin.y = NSMaxY(cur) - newFrame.size.height;

    if (animate) [self.window setFrame:newFrame display:YES animate:YES];
    else         [self.window setFrame:newFrame display:YES];

    self.window.contentViewController = vc;
    
    if([paneID isEqualTo:kPaneIDNotifications]) {
        self.window.title = @"Notifications";
    }
    
    else {
        self.window.title = @"General";
    }
    
    [self.toolbar setSelectedItemIdentifier:paneID];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[kPaneIDGeneral, kPaneIDNotifications];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[kPaneIDGeneral, kPaneIDNotifications];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return @[kPaneIDGeneral, kPaneIDNotifications];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    if ([itemIdentifier isEqualToString:kPaneIDGeneral]) {
        item.label = @"General";
        item.paletteLabel = @"General";
        item.target = self;
        item.action = @selector(onToolbarSelect:);
        if (@available(macOS 11.0, *)) {
            item.image = [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:@"General"];
        } else {
            item.image = [NSImage imageNamed:NSImageNamePreferencesGeneral];
        }
    } else if ([itemIdentifier isEqualToString:kPaneIDNotifications]) {
        item.label = @"Notifications";
        item.paletteLabel = @"Notifications";
        item.target = self;
        item.action = @selector(onToolbarSelect:);
        if (@available(macOS 11.0, *)) {
            item.image = [NSImage imageWithSystemSymbolName:@"bell" accessibilityDescription:@"Notifications"];
        } else {
            item.image = [NSImage imageNamed:NSImageNameCaution]; // fallback icon
        }
    }

    return item;
}

- (void)onToolbarSelect:(NSToolbarItem *)sender {
    NSString *paneID = sender.itemIdentifier;
    [self switchToPane:paneID animate:YES];
}

@end
