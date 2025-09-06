//
//  AppDelegate.m
//  decline
//
//  Created by Derek Scott on 5/12/25.
//

#import <CoreFoundation/CoreFoundation.h>  // for CFSwapInt64BigToHost
#import <Cocoa/Cocoa.h>
#import <arpa/inet.h>

#import "AppDelegate.h"
#import "AppIconManager.h"
#import "AppSupport.h"
#import "CustomNotification.h"
#import "CustomNotificationManager.h"
#import "CustomTextFieldWithPopup.h"
#import "NSAttributedString+RTFAdditions.h"
#import "NSColor+Hex.h"
#import "ThemedBackgroundView.h"

#import "PreferencesWindowController.h"
#import "ChangeNickIconViewController.h"
#import "SendBroadcastViewController.h"
#import "SendNewsPostViewController.h"
#import "ShowAgreementViewController.h"

@interface AppDelegate ()

@end

NSUserDefaults *defaults;

@implementation AppDelegate

- (IBAction)showPreferences:(id)sender {
    [[PreferencesWindowController sharedController] showWindow:self];
}

- (void)setupMainMenu {
    // Create the main menu bar
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@""];

    //
    // ─── Application menu ─────────────────────────────────
    //
    NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [mainMenu addItem:appItem];

    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@""];
    NSString *appName = [[NSProcessInfo processInfo] processName];

    // About
    [appMenu addItemWithTitle:[NSString stringWithFormat:@"About %@", appName]
                       action:@selector(orderFrontStandardAboutPanel:)
                keyEquivalent:@""];

    [appMenu addItem:[NSMenuItem separatorItem]];

    // Preferences…
    [appMenu addItemWithTitle:@"Preferences…"
                       action:@selector(showPreferences:)
                keyEquivalent:@","];

    [appMenu addItem:[NSMenuItem separatorItem]];

    // Hide, Hide Others, Show All
    [appMenu addItemWithTitle:[NSString stringWithFormat:@"Hide %@", appName]
                       action:@selector(hide:)
                keyEquivalent:@"h"];

    NSMenuItem *hideOthers = [[NSMenuItem alloc] initWithTitle:@"Hide Others"
                                                         action:@selector(hideOtherApplications:)
                                                  keyEquivalent:@"h"];
    hideOthers.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
    [appMenu addItem:hideOthers];

    [appMenu addItemWithTitle:@"Show All"
                       action:@selector(unhideAllApplications:)
                keyEquivalent:@""];

    [appMenu addItem:[NSMenuItem separatorItem]];

    // Quit
    [appMenu addItemWithTitle:[NSString stringWithFormat:@"Quit %@", appName]
                       action:@selector(terminate:)
                keyEquivalent:@"q"];

    [appItem setSubmenu:appMenu];

    //
    // ─── File menu ───────────────────────────────────────
    //
    NSMenuItem *fileItem = [[NSMenuItem alloc] initWithTitle:@"File" action:NULL keyEquivalent:@""];
    [mainMenu addItem:fileItem];

    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    // New Connection
    [fileMenu addItemWithTitle:@"New Connection…"
                       action:@selector(newConnection:)
                keyEquivalent:@"N"];
  
    [fileMenu addItem:[NSMenuItem separatorItem]];
    // Close Window
    [fileMenu addItemWithTitle:@"Close Window"
                       action:@selector(performClose:)
                keyEquivalent:@"W"];

    [fileItem setSubmenu:fileMenu];

    //
    // ─── Edit menu ───────────────────────────────────────
    //
    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:NULL keyEquivalent:@""];
    [mainMenu addItem:editItem];

    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Undo"       action:@selector(undo)       keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo"       action:@selector(redo)       keyEquivalent:@"Z"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cut"        action:@selector(cut:)        keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy"       action:@selector(copy:)       keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste"      action:@selector(paste:)      keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:)  keyEquivalent:@"a"];
    [editItem setSubmenu:editMenu];

    //
    // ─── Window menu ─────────────────────────────────────
    //
    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:NULL keyEquivalent:@""];
    [mainMenu addItem:windowItem];

    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Minimize"
                          action:@selector(miniaturize:)
                   keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom"
                          action:@selector(zoom:)
                   keyEquivalent:@""];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Bring All to Front"
                          action:@selector(arrangeInFront:)
                   keyEquivalent:@""];

    [windowItem setSubmenu:windowMenu];
    // Tell AppKit that this is our “Window” menu
    [NSApp setWindowsMenu:windowMenu];

    //
    // ─── Help menu ───────────────────────────────────────
    //
    NSMenuItem *helpItem = [[NSMenuItem alloc] initWithTitle:@"Help" action:NULL keyEquivalent:@""];
    [mainMenu addItem:helpItem];

    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenu addItemWithTitle:[NSString stringWithFormat:@"%@ Help", appName]
                         action:@selector(showHelp:)
                  keyEquivalent:@"?"];
    [helpItem setSubmenu:helpMenu];

    // Finally, install it
    [NSApp setMainMenu:mainMenu];
}

- (void)hideOtherApps {
    [[NSWorkspace sharedWorkspace] hideOtherApplications];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

-  (void)application:(NSApplication *)sender openURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        NSLog(@"Received URL: %@", url.absoluteString);

        // Parse the URL components
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSString *scheme = components.scheme;
        NSString *host = components.host;
        NSNumber *port = components.port; // Extract the port

        NSLog(@"Scheme: %@", scheme);
        NSLog(@"Host: %@", host);
        NSLog(@"Port: %@", port ? port.stringValue : @"No port"); // Log the port

        // Combine host and port if it exists
        NSString *hostWithPort = port ? [NSString stringWithFormat:@"%@:%@", host, port] : host;

        if(self.clients.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSEvent *keyDownEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown
                                                             location:NSMakePoint(0, 0)
                                                        modifierFlags:0
                                                            timestamp:0
                                                         windowNumber:0
                                                              context:nil
                                                          characters:@"\r"
                                         charactersIgnoringModifiers:@"\r"
                                                           isARepeat:NO
                                                             keyCode:36];
                
                if([self.clients lastObject].uiState == ClientUIStateConnect) {
                    HotlineClient *client = [self.clients lastObject];
                    client.serverField.textField.stringValue = [NSString stringWithFormat:@"%@", hostWithPort];
                    [client serverFieldUpdated];
                    [client.connectButton performKeyEquivalent:keyDownEvent];
                }
                
                else {
                    [self newConnection];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        HotlineClient *client = [self.clients lastObject];
                        client.serverField.textField.stringValue = [NSString stringWithFormat:@"%@", hostWithPort];
                        [client serverFieldUpdated];
                        [client.connectButton performKeyEquivalent:keyDownEvent];
                    });
                }
            });
        }
    }
}

-  (void)applicationWillTerminate:(NSNotification *)aNotification {
    
    // Clean up
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
    
    defaults = [NSUserDefaults standardUserDefaults];

    [defaults registerDefaults:@{
        @"DefaultNick": @"decline n00b",
        @"DefaultIcon": @"148",
        @"ShowJoinLeaveMessages": @NO,
        @"ShowNickChangeMessages": @NO,
        @"ShowUserlistOnRightSide" : @YES,
        @"ShowChatSendButton" : @NO,
        @"NotificationsEnabled" : @YES,
        @"NotificationTextSize" : @(NotificationTextSizeMedium),
        @"NotificationPosition" : @(NotificationPositionCenter),
        @"NotificationSticky" : @YES
    }];
       
    //Nuke prefs
    /*NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [defaults removePersistentDomainForName:appDomain];
    [defaults synchronize];*/
    
    [AppIconManager updateDockIconToMatchCurrentAppearance];
        
    [self setupMainMenu];
    
    self.clients = [NSMutableArray array];
    
    [self newConnection:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(interfaceModeChanged:)
                                            name:@"AppleInterfaceThemeChangedNotification"
                                            object:nil];

    // Observe system wake
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                             selector:@selector(systemDidWake:)
                                                 name:NSWorkspaceDidWakeNotification
                                               object:nil];
}

- (IBAction)newConnection:(id)sender {
    [self.clients addObject:[[HotlineClient alloc] init]];
}

- (void)newConnection {
    [self newConnection:nil];
}

- (void)removeClient:(NSUUID*)uuid {
    
    // Find the index of the client with that UUID
    NSUInteger idx = [self.clients indexOfObjectPassingTest:^BOOL(HotlineClient *client, NSUInteger idx, BOOL *stop) {
        if ([client.uuid isEqual:uuid]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    // If found, remove it
    if (idx != NSNotFound) {
        [self.clients removeObjectAtIndex:idx];
    }
}

- (void)tileAllWindows {
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect vis = [mainScreen visibleFrame];  // skip menu + dock
    NSUInteger count = self.clients.count;
    
    NSUInteger cols = ceil(sqrt(count));
    NSUInteger rows = (count + cols - 1) / cols;
    CGFloat w = vis.size.width  / cols;
    CGFloat h = vis.size.height / rows;

    [self.clients enumerateObjectsUsingBlock:^(HotlineClient *client, NSUInteger idx, BOOL *stop) {
        NSUInteger row = idx / cols;
        NSUInteger col = idx % cols;
        NSRect f = NSMakeRect(
            vis.origin.x + col * w,
            vis.origin.y + (rows - row - 1) * h,
            w, h
        );
        [client.window setFrame:f display:YES animate:NO];
        [client.chatTextView scrollToEndOfDocument:nil];
    }];
}

- (void)updateChatView {
    for (HotlineClient *client in self.clients) {
        [client updateChatView];
    }
}

- (void)interfaceModeChanged:(NSNotification *)note {
    [AppIconManager updateDockIconToMatchCurrentAppearance];
}

-  (void)systemDidWake:(NSNotification *)notification {
    NSLog(@"System has woken up.");
    // Handle system wake
    
    for (HotlineClient *client in self.clients) {
        if(client.handshakeState == HandshakeStateConnected) {
            [client.transactions sendGetUserListTransactionForStream:client.outputStream];
        }
    }
}

@end
