//
//  HotlineClient.m
//  decline
//
//  Created by Derek Scott on 6/12/25.
//

#import "HotlineClient.h"
#import "AppDelegate.h"

@implementation HotlineClient {
}

- (instancetype)init {
    
    if (self = [super init]) {
    
        self.uuid = [NSUUID UUID];
        
        self.servers = [[NSMutableArray alloc] init];
        
        NSArray *serverlist = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Servers"];
        [self.servers addObjectsFromArray:serverlist];
        
        self.showAgreementMessage = YES;
        
        // create a single window
        /*NSRect frame = NSMakeRect(0, 0, kConnectWidth, kConnectHeight);
        self.window = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                                             NSWindowStyleMaskMiniaturizable)
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
        
        self.connectWindowFrame = self.window.frame;
        
        [self.window center];
        [self.window setTitle:@"New Connection"];
        [self.window makeKeyAndOrderFront:nil];
        self.window.delegate = self;
        self.window.restorable = NO;*/
        
        NSRect frame = NSMakeRect(0, 0, kConnectWidth, kConnectHeight);
        self.connectionWindow = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                                             NSWindowStyleMaskMiniaturizable)
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
        
        self.connectWindowFrame = self.connectionWindow.frame;
        
        [self.connectionWindow center];
        [self.connectionWindow setTitle:@"New Connection"];
        self.connectionWindow.restorable = NO;
        [self.connectionWindow makeKeyAndOrderFront:nil];
        
        self.cachedChatContents = [[NSMutableAttributedString alloc] init];
        self.transactions = [[UserTransactions alloc] init];
        self.fileTransfers = [[NSMutableArray alloc] init];
        
        self.downloads = [[NSMutableArray alloc] init];
        self.downloadsVC = [[DownloadsViewController alloc] init];
        self.downloadsPopover = [[NSPopover alloc] init];
        self.downloadsPopover.behavior          = NSPopoverBehaviorTransient;
        self.downloadsPopover.contentSize       = NSMakeSize(300,400);
        self.downloadsPopover.contentViewController = self.downloadsVC;
        
        self.awaitingOpenUser = NO;
        self.awaitingModifyReply = NO;
        
        self.canDownloadFile = NO;
        self.canDownloadFolder = NO;
        self.canUploadFile = NO;
        self.canUploadFolder = NO;
        self.canReadNews = NO;
        self.canPostNews = NO;
        self.canSendBroadcast = NO;
        self.canSendMessage = NO;
        
        self.processUserListCalled = NO;
        self.hasReceivedInitialUserList = NO;
        self.users = [NSMutableArray array];
        
        self.processNewsCalled = NO;
        self.hasReceivedInitialNews = NO;
        self.newsItems = [NSMutableArray array];
        
        self.directoryCache = [NSMutableDictionary dictionary];
        self.filesModel = [NSMutableArray array];
        self.filePath = @"/";
        
        self.networkThread = [[NSThread alloc] initWithTarget:self
                                                        selector:@selector(_networkThreadEntryPoint)
                                                          object:nil];
        
        self.networkThread.name = @"la.dubs.decline.NetworkThread";
        
        // Start the thread—this will invoke -_networkThreadEntryPoint and spin up its run loop.
        
        [self.networkThread start];
        
        self.uiState = ClientUIStateConnect;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.connectionWindow.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self buildConnectUI];
        });
    }
    
    return self;
}
    
- (void)buildConnectUI {
    NSView *c = self.connectionWindow.contentView;
    
    // — label factory —
    NSTextField*(^makeLabel)(NSString*) = ^(NSString *txt) {
        NSTextField *lbl = [NSTextField labelWithString:txt];
        lbl.translatesAutoresizingMaskIntoConstraints = NO;
        return lbl;
    };
    
    // Create all labels
    NSTextField *lblServer    = makeLabel(@"Server:"),
    *lblLogin     = makeLabel(@"Login:"),
    *lblPassword  = makeLabel(@"Password:"),
    *lblNick      = makeLabel(@"Nickname:");
    
    // Create all controls
    NSRect textFieldFrame = NSMakeRect(20, 100, 200, 24);
    self.serverField  = [[CustomTextFieldWithPopup alloc] initWithFrame:textFieldFrame];
    
    // Set SF Symbol
    self.serverField.textField.stringValue = @"";
    [self.serverField setPopupButtonSymbolName:@""];
    
    // Create popup menu
    self.bookmarkMenu = [[NSMenu alloc] init];
    
    self.serverField.popupButton.target = self;
    self.serverField.popupButton.action = @selector(showPopupMenu:);
    
    self.serverField.popupMenu = self.bookmarkMenu;
    self.loginField    = [self makeTextField:@""];
    self.passwordField = [self makeSecureField:@""];
    
    self.nickField = [self makeTextField:@""];
    NSString *defaultNick = [[NSUserDefaults standardUserDefaults]
                             stringForKey:@"DefaultNick"];
    
    if(defaultNick != nil) {
        self.nickField.stringValue = defaultNick;
    }
    
    else {
        self.nickField.stringValue = @"decline n00b";
    }
    
    // nextKeyView chain
    self.serverField.textField.nextKeyView   = self.loginField;
    self.loginField.nextKeyView    = self.passwordField;
    self.passwordField.nextKeyView = self.nickField;
    self.nickField.nextKeyView     = self.serverField.textField;
    
    // Build each horizontal row:
    NSStackView *rowServer    = [self rowWithSubviews:@[ lblServer,    self.serverField   ]];
    NSStackView *rowLogin     = [self rowWithSubviews:@[ lblLogin,     self.loginField    ]];
    NSStackView *rowPassword  = [self rowWithSubviews:@[ lblPassword,  self.passwordField ]];
    NSStackView *rowNick      = [self rowWithSubviews:@[ lblNick,      self.nickField     ]];
    
    // Stack them vertically:
    NSStackView *formStack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    formStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    formStack.spacing     = 8;   // the default spacing between *all* rows
    formStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    [formStack addArrangedSubview:rowServer];
    [formStack addArrangedSubview:rowLogin];
    [formStack addArrangedSubview:rowPassword];
    
    [formStack addArrangedSubview:rowNick];
    [c addSubview:formStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [formStack.leadingAnchor  constraintEqualToAnchor:c.leadingAnchor constant:20],
        [formStack.trailingAnchor constraintEqualToAnchor:c.trailingAnchor constant:-20],
        [formStack.topAnchor      constraintEqualToAnchor:c.topAnchor constant:20],
    ]];
    
    // Make all labels the same width:
    [NSLayoutConstraint activateConstraints:@[
        [lblLogin.widthAnchor     constraintEqualToAnchor:lblServer.widthAnchor],
        [lblPassword.widthAnchor  constraintEqualToAnchor:lblServer.widthAnchor],
        [lblNick.widthAnchor      constraintEqualToAnchor:lblServer.widthAnchor],
    ]];
    
    // Make all controls the same width as the server field:
    [NSLayoutConstraint activateConstraints:@[
        [self.loginField.widthAnchor    constraintEqualToAnchor:self.serverField.widthAnchor],
        [self.passwordField.widthAnchor constraintEqualToAnchor:self.serverField.widthAnchor],
        [self.nickField.widthAnchor     constraintEqualToAnchor:self.serverField.widthAnchor],
    ]];
    
    // Finally, the Connect button beneath everything:
    self.connectButton = [self makeButton:@"Connect" action:@selector(onConnect:)];
    self.connectButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.connectButton.keyEquivalent = @"\r";
    [c addSubview:self.connectButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.connectButton.centerXAnchor constraintEqualToAnchor:c.centerXAnchor],
        [self.connectButton.topAnchor     constraintEqualToAnchor:formStack.bottomAnchor constant:20],
    ]];
    
    self.connectionWindow.initialFirstResponder = self.serverField;
    [self.connectionWindow makeFirstResponder:self.serverField.textField];
}

- (NSStackView*)rowWithSubviews:(NSArray<NSView*>*)views {
    NSStackView *row = [[NSStackView alloc] initWithFrame:NSZeroRect];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing     = 8;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSView *v in views) [row addArrangedSubview:v];
    return row;
}

-  (void)sortMenu:(NSMenu *)menu {
    // Extract the menu items
    NSMutableArray *menuItems = [NSMutableArray array];
    
    for (NSMenuItem *item in menu.itemArray) {
        [menuItems addObject:item];
    }
    
    // Sort the items
    [menuItems sortUsingComparator:^NSComparisonResult(NSMenuItem *item1, NSMenuItem *item2) {
        return [item1.title compare:item2.title];
    }];
    
    // Clear the existing menu and add sorted items
    [menu removeAllItems];
    
    for (NSMenuItem *sortedItem in menuItems) {
        [menu addItem:sortedItem];
    }
}

- (void)showPopupMenu:(NSButton *)sender {     //Repopulate bookmark menu
    [self.bookmarkMenu removeAllItems];
    
    NSUInteger index = [self.servers indexOfObjectPassingTest:^BOOL(NSString *string, NSUInteger idx, BOOL *stop) {
        return [string caseInsensitiveCompare:self.serverField.textField.stringValue] == NSOrderedSame;
    }];
    
    for (NSString * server in self.servers) {
        NSMenuItem *selectBm = [self.bookmarkMenu addItemWithTitle:server
                                     action:@selector(onSelectBookmark:)
                              keyEquivalent:@""];
        
        selectBm.target = self;
    }
        
    if(![self.serverField.textField.stringValue isEqualToString:@""]) {
        if (index != NSNotFound) {
            [self.bookmarkMenu addItem:[NSMenuItem separatorItem]];
            NSMenuItem *removeBm = [self.bookmarkMenu addItemWithTitle:@"Remove Bookmark"
                                         action:@selector(onRemoveBookmark:)
                                  keyEquivalent:@""];
            removeBm.target = self;
        } else {
            [self.bookmarkMenu addItem:[NSMenuItem separatorItem]];
            NSMenuItem *addBm = [self.bookmarkMenu addItemWithTitle:@"Add Bookmark"
                                         action:@selector(onAddBookmark:)
                                  keyEquivalent:@""];
            addBm.target = self;
        }
    }
    
    [self sortMenu:self.bookmarkMenu];
    
    self.serverField.popupMenu = self.bookmarkMenu;
    
    if (self.serverField.popupMenu) {
        NSRect buttonFrame = sender.frame;
        NSPoint menuOrigin = NSMakePoint(NSMinX(buttonFrame), NSMaxY(buttonFrame));
        menuOrigin = [self.serverField convertPoint:menuOrigin toView:nil];
        
        NSEvent *event = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                            location:menuOrigin
                                       modifierFlags:0
                                           timestamp:0
                                        windowNumber:self.connectionWindow.windowNumber
                                             context:nil
                                         eventNumber:0
                                          clickCount:1
                                            pressure:1.0];
        
        [NSMenu popUpContextMenu:self.serverField.popupMenu withEvent:event forView:sender];
    }
}

- (void)onAddBookmark:(id)sender {
    [self.servers addObject:self.serverField.textField.stringValue];
    [[NSUserDefaults standardUserDefaults] setObject:self.servers forKey:@"Servers"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)onRemoveBookmark:(id)sender {
    [self.servers removeObject:self.serverField.textField.stringValue];
    [[NSUserDefaults standardUserDefaults] setObject:self.servers forKey:@"Servers"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)onSelectBookmark:(id)sender {
    NSMenuItem *item = (NSMenuItem *) sender;
    self.serverField.textField.stringValue = item.title;
}

- (NSTextField*)makeTextField:(NSString*)ph {
    NSTextField *tf = [[NSTextField alloc] initWithFrame:NSZeroRect];
    tf.placeholderString = ph;
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    return tf;
}

- (NSSecureTextField*)makeSecureField:(NSString*)ph {
    NSSecureTextField *tf = [[NSSecureTextField alloc] initWithFrame:NSZeroRect];
    tf.placeholderString = ph;
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    return tf;
}

- (NSButton*)makeButton:(NSString*)title action:(SEL)sel {
    NSButton *b = [[NSButton alloc] initWithFrame:NSZeroRect];
    b.title      = title;
    b.bezelStyle = NSBezelStyleRounded;
    b.target     = self;
    b.action     = sel;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    return b;
}

#pragma mark – Transition to Chat UI

- (void)transformToChatUI {
    [self.connectionWindow orderOut:nil];
    
    NSRect frame = NSMakeRect(0, 0, kConnectWidth, kConnectHeight);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                                         NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    [self.window setTitle:self.serverField.textField.stringValue];
    self.window.delegate = self;
    self.window.restorable = NO;

    //Install toolbar
    NSToolbar *tb = [[NSToolbar alloc] initWithIdentifier:@"Toolbar"];
    tb.delegate = self;
    tb.displayMode = NSToolbarDisplayModeIconOnly;
    [self.window setToolbar:tb];
    [self.window setContentSize:NSMakeSize(kChatWidth, kChatHeight)];
    
    [self.window makeKeyAndOrderFront:nil];
    
    AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
    [appDel tileAllWindows];

    [self showChatView:nil];
}

#pragma mark – NSToolbarDelegate

/*- (NSArray<NSString*>*)toolbarAllowedItemIdentifiers:(NSToolbar*)t {
    return @[NSToolbarFlexibleSpaceItemIdentifier,@"ULToggle",@"ChangeNick",@"OpenUser",@"SendBroadcast",@"ToggleBroadcastPriv",NSToolbarSpaceItemIdentifier,@"Chat",@"News", NSToolbarSpaceItemIdentifier,@"Disconnect"];
}
- (NSArray<NSString*>*)toolbarDefaultItemIdentifiers:(NSToolbar*)t {
    return @[NSToolbarFlexibleSpaceItemIdentifier,@"ULToggle",@"ChangeNick",@"OpenUser",@"SendBroadcast",@"ToggleBroadcastPriv",NSToolbarSpaceItemIdentifier,@"Chat",@"News", NSToolbarSpaceItemIdentifier,@"Disconnect"];
}*/

- (NSArray<NSString*>*)toolbarAllowedItemIdentifiers:(NSToolbar*)t {
    return @[@"New Connection", NSToolbarFlexibleSpaceItemIdentifier,@"Chat",@"News",@"Files",@"Downloads",NSToolbarFlexibleSpaceItemIdentifier,@"NewPost",@"SendBroadcast",@"ChangeNickIcon",@"ULToggle",NSToolbarFlexibleSpaceItemIdentifier,@"Disconnect"];
}
- (NSArray<NSString*>*)toolbarDefaultItemIdentifiers:(NSToolbar*)t {
    return @[@"New Connection", NSToolbarFlexibleSpaceItemIdentifier,@"Chat",@"News",@"Files",@"Downloads",NSToolbarFlexibleSpaceItemIdentifier,@"NewPost",@"SendBroadcast",@"ChangeNickIcon",@"ULToggle",NSToolbarFlexibleSpaceItemIdentifier,@"Disconnect"];
}
- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar
    itemForItemIdentifier:(NSString*)ident
    willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *ti = [[NSToolbarItem alloc] initWithItemIdentifier:ident];
    ti.target = self;
    ti.bordered = YES;
    
    if ([ident isEqualToString:@"New Connection"]) {
        ti.label = @"New Connection";
        ti.image = [NSImage imageWithSystemSymbolName:@"macwindow.badge.plus"
                               accessibilityDescription:@"New Connection"];
        ti.action = @selector(newConnection:);
    }
    
    else if ([ident isEqualToString:@"Chat"]) {
        ti.label = @"Chat";
        ti.image = [NSImage imageWithSystemSymbolName:@"bubble.left.and.bubble.right"
                               accessibilityDescription:@"Chat"];
        ti.action = @selector(showChatView:);
    }
    else if ([ident isEqualToString:@"News"]) {
        ti.label = @"News";
        ti.image = [NSImage imageWithSystemSymbolName:@"newspaper"
                               accessibilityDescription:@"News"];
        ti.action = @selector(showNewsView:);
    }
    else if ([ident isEqualToString:@"Files"]) {
        ti.label = @"Files";
        ti.image = [NSImage imageWithSystemSymbolName:@"folder"
                               accessibilityDescription:@"Files"];
        ti.action = @selector(showFilesView:);
    }
    else if ([ident isEqualToString:@"Downloads"]) {
        ti.label = @"Downloads";
        ti.paletteLabel = @"Downloads";

        /*ti.image = [NSImage imageWithSystemSymbolName:@"arrow.down.circle"
                               accessibilityDescription:@"Downloads"];*/
        //ti.action = @selector(showFilesView:);
        
        // pick your icon – Safari uses a custom template, you can use a SF Symbol:
        NSImage *icon = [NSImage imageWithSystemSymbolName:@"arrow.down.circle" accessibilityDescription:@"Downloads"];
        [icon setTemplate:YES];

        // a plain NSButton works fine:
        self.downloadButton = [NSButton buttonWithTitle:@"" image:icon target:self action:@selector(toggleDownloads:)];
        self.downloadButton.bezelStyle = NSBezelStyleTexturedRounded;
        self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.downloadButton.widthAnchor  constraintEqualToConstant:32].active = YES;
        [self.downloadButton.heightAnchor constraintEqualToConstant:32].active = YES;

        ti.view = self.downloadButton;
    }
    else if ([ident isEqualToString:@"NewPost"]) {
        ti.label = @"New News Post";
        ti.image = [NSImage imageWithSystemSymbolName:@"square.and.pencil"
                               accessibilityDescription:@"New Post"];
        ti.action = @selector(newPost:);
    }
    else if ([ident isEqualToString:@"ChangeNickIcon"]) {
        ti.label = @"Change Nick/Icon";
        ti.image = [NSImage imageWithSystemSymbolName:@"arrow.triangle.2.circlepath"
                               accessibilityDescription:@"Change Nick/Icon"];
        ti.action = @selector(changeNickAndIcon:);
    }
    else if ([ident isEqualToString:@"ULToggle"]) {
        ti.label = @"Userlist Toggle";
        ti.image = [NSImage imageWithSystemSymbolName:@"person.fill.and.arrow.left.and.arrow.right.outward"
                             accessibilityDescription:@"Toggle Userlist Location Left/Right"];
        ti.action = @selector(toggleUserListPosition:);
    }
    /*else if ([ident isEqualToString:@"OpenUser"]) {
        ti.label = @"Open User";
        ti.image = [NSImage imageWithSystemSymbolName:@"person.circle.fill"
                             accessibilityDescription:@"Open User"];
        ti.action = @selector(openUser:);
    }*/
    else if ([ident isEqualToString:@"SendBroadcast"]) {
        ti.label = @"Send Broadcast";
        ti.image = [NSImage imageWithSystemSymbolName:@"antenna.radiowaves.left.and.right"
                             accessibilityDescription:@"Send Broadcast"];
        ti.action = @selector(sendBroadcast:);
    }
    /*else if ([ident isEqualToString:@"ToggleBroadcastPriv"]) {
        ti.label = @"Toggle BPriv";
        ti.image = [NSImage imageWithSystemSymbolName:@"dot.radiowaves.left.and.right"
                             accessibilityDescription:@"Toggle BPriv"];
        ti.action = @selector(toggleBroadcastPrivilegeOff:);
    }*/
    else if ([ident isEqualToString:@"Disconnect"]) {
        ti.label = @"Disconnect";
        ti.image = [NSImage imageWithSystemSymbolName:@"power"
                               accessibilityDescription:@"Disconnect"];
        ti.action = @selector(onDisconnect:);
    }
    
    else if ([ident isEqualToString:NSToolbarFlexibleSpaceItemIdentifier]) {
        ti = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
    }
    
    else if ([ident isEqualToString:NSToolbarSpaceItemIdentifier]) {
        ti = [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarSpaceItemIdentifier];
    }

    return ti;
}

- (void)toggleDownloads:(NSButton*)sender {
  if (self.downloadsPopover.isShown) {
    [self.downloadsPopover close];
  }
    
  else {
    [self.downloadsPopover showRelativeToRect:sender.bounds
                                       ofView:sender
                                preferredEdge:NSRectEdgeMinY];
  }
}

// Validate toolbar items to enable/disable them
-  (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSString *itemIdentifier = toolbarItem.itemIdentifier;

    
    if ([itemIdentifier isEqualToString:@"News"]) {
        if (self.canReadNews) {
            return YES;
        }
            
        else {
            return NO;
        }
    }
    else if ([itemIdentifier isEqualToString:@"Files"]) {
        if (self.canDownloadFile || self.canDownloadFolder || self.canUploadFile || self.canUploadFolder) {
            return YES;
        }
            
        else {
            return NO;
        }
    }
    else if ([itemIdentifier isEqualToString:@"NewPost"]) {
        if (self.canPostNews) {
            return YES;
        }
            
        else {
            return NO;
        }
    }
    else if ([itemIdentifier isEqualToString:@"SendBroadcast"]) {
        if (self.canSendBroadcast) {
            return YES;
        }
            
        else {
            return NO;
        }
    }

    return YES; // Default behavior: all other items are enabled
}

- (IBAction)newConnection:(id)sender {
    AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
    [appDel newConnection];
}

- (IBAction)showChatView:(id)sender {
    if(self.uiState == ClientUIStateChat) {
        return;
    }
    
    else {
        self.uiState = ClientUIStateChat;
        [self updateChatView];
    }
}

- (IBAction)showNewsView:(id)sender {
    if(self.uiState == ClientUIStateNews) {
        return;
    }
    
    else {
        self.uiState = ClientUIStateNews;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.window.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self buildNewsUI];
        });
    }
}

- (IBAction)showFilesView:(id)sender {
    if(self.uiState == ClientUIStateFiles) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.filesTableView reloadData];
        });
        return;
    }
    
    else {
        self.uiState = ClientUIStateFiles;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.window.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self buildFilesUI];
        });
    }
}

- (IBAction)sendBroadcast:(id)sender {
    SendBroadcastViewController *vc = [[SendBroadcastViewController alloc] init];
    vc.completionHandler = ^(NSString *broadcastText) {
        if (broadcastText.length) {
            [self.transactions sendBroadcastTransaction:broadcastText forStream:self.outputStream];
        }
    };
    
    self.broadcastSheetWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 130)
                                                            styleMask:(NSWindowStyleMaskTitled)
                                                              backing:NSBackingStoreBuffered
                                                                defer:NO];
    self.broadcastSheetWindow.contentViewController = vc;
    
    [self.window beginSheet:self.broadcastSheetWindow completionHandler:^(NSModalResponse returnCode) {
        self.broadcastSheetWindow = nil;
    }];
}

- (IBAction)newPost:(id)sender {
    SendNewsPostViewController *vc = [[SendNewsPostViewController alloc] init];
    vc.completionHandler = ^(NSString *newsText) {
        if (newsText.length) {
            [self.transactions sendPostNewsTransactionWithPost:newsText forStream:self.outputStream];
        }
    };
    
    self.newsPostSheetWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 360)
                                                           styleMask:(NSWindowStyleMaskTitled)
                                                             backing:NSBackingStoreBuffered
                                                               defer:NO];
    self.newsPostSheetWindow.contentViewController = vc;
    
    [self.window beginSheet:self.newsPostSheetWindow completionHandler:^(NSModalResponse returnCode) {
        self.newsPostSheetWindow = nil;
    }];
}

- (IBAction)changeNickAndIcon:(id)sender {
    ChangeNickIconViewController *vc =
    [[ChangeNickIconViewController alloc] initWithNickname:self.nickname
                                                iconNumber:self.iconNumber];
    vc.completionHandler = ^(NSString *nickname, uint32_t iconNumber) {
        self.nickname = nickname;
        self.iconNumber = iconNumber;
        [self.transactions sendSetUserInfoTransactionWithNick:self.nickname iconNum:self.iconNumber forStream:self.outputStream];
    };
    
    self.nickSheetWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 160)
                                                       styleMask:(NSWindowStyleMaskTitled)
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
    self.nickSheetWindow.contentViewController = vc;
    
    [self.window beginSheet:self.nickSheetWindow completionHandler:^(NSModalResponse returnCode) {
        self.nickSheetWindow = nil;
    }];
}

- (IBAction)toggleBroadcastPrivilegeOff:(id)sender {
    //[self toggleBroadcastAndPrivMsg];
}

- (IBAction)toggleUserListPosition:(id)sender {
    
    BOOL showRight = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUserlistOnRightSide"];
    
    if(showRight) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowUserlistOnRightSide"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowUserlistOnRightSide"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self updateChatView];
}

/*- (IBAction)openUser:(id)sender {
    // Create the alert as a sheet
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText    = @"Open User";
    alert.informativeText = @"Enter username:";
    alert.alertStyle     = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    // Add a text‐field as the accessory view
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    field.stringValue = @"";
    alert.accessoryView = field;
    
    // Show as sheet on your main window
    [alert beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            // user clicked “OK”
            NSString *username = field.stringValue;
            if (username.length > 0) {
                [self sendOpenUserTransaction:username forStream:self.outputStream];
            }
        }
    }];
}*/


- (void)updateChatView {
    
    if(self.uiState == ClientUIStateChat) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.window.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self buildChatUI];
        });
    }
}

#pragma mark – Chat UI

// AppDelegate.m
- (void)buildChatUI {
    NSView *ct = self.window.contentView;
    
    // Create & pin the split view
    NSSplitView *splitView = [[NSSplitView alloc] initWithFrame:ct.bounds];
    splitView.translatesAutoresizingMaskIntoConstraints = NO;
    splitView.vertical       = YES;
    splitView.dividerStyle   = NSSplitViewDividerStyleThin;
    [ct addSubview:splitView];
    [NSLayoutConstraint activateConstraints:@[
      [splitView.leadingAnchor  constraintEqualToAnchor:ct.leadingAnchor],
      [splitView.trailingAnchor constraintEqualToAnchor:ct.trailingAnchor],
      [splitView.topAnchor      constraintEqualToAnchor:ct.topAnchor],
      [splitView.bottomAnchor   constraintEqualToAnchor:ct.bottomAnchor],
    ]];

    // Build the user-list pane (fixed width)
    NSScrollView *userScroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    userScroll.translatesAutoresizingMaskIntoConstraints = NO;
    userScroll.hasVerticalScroller   = YES;
    userScroll.hasHorizontalScroller = NO;
    [userScroll.widthAnchor constraintEqualToConstant:200].active = YES;

    NSTableView *userTable = [[NSTableView alloc] initWithFrame:NSZeroRect];
    userTable.headerView   = nil;
    userTable.delegate     = self;
    userTable.dataSource   = self;
    userTable.rowHeight    = 24;
    NSTableColumn *col     = [[NSTableColumn alloc] initWithIdentifier:@"nick"];
    col.title = @"Users";
    [userTable addTableColumn:col];
    userScroll.documentView = userTable;
    self.userListView = userTable;

    // Build the chat pane
    ThemedBackgroundView *chatPane = [[ThemedBackgroundView alloc] initWithFrame:NSZeroRect];
    chatPane.translatesAutoresizingMaskIntoConstraints = NO;

    // — the scroll view (Auto-Layout controlled)
    NSScrollView *chatScroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    chatScroll.translatesAutoresizingMaskIntoConstraints     = NO;
    chatScroll.hasVerticalScroller   = YES;
    chatScroll.hasHorizontalScroller = NO;
    chatScroll.autohidesScrollers    = NO;
    chatScroll.borderType            = NSNoBorder;
    chatScroll.drawsBackground       = NO;
    [chatPane addSubview:chatScroll];
    self.chatScrollView = chatScroll;

    // — the text view inside it (no Auto-Layout; uses autoresizing)
    NSTextView *chatTV = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,0,500)];
    chatTV.minSize               = NSMakeSize(0,0);
    chatTV.maxSize               = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    chatTV.verticallyResizable   = YES;
    chatTV.horizontallyResizable = NO;
    chatTV.textContainerInset    = NSMakeSize(5,5);
    chatTV.textContainer.widthTracksTextView  = YES;
    chatTV.textContainer.heightTracksTextView = NO;
    chatTV.backgroundColor       = [NSColor clearColor];
    chatTV.drawsBackground       = NO;
    chatTV.editable              = NO;
    chatTV.selectable            = YES;
    chatTV.font                  = [NSFont systemFontOfSize:12];
    chatTV.autoresizingMask      = NSViewWidthSizable;
    
    // turn on automatic link detection
    // this will scan the text and wrap anything that looks like http://… or https://… in an NSLink attribute
    chatTV.automaticLinkDetectionEnabled = YES;

    // only detect links (you can OR in other NSTextCheckingType bits if you like)
    chatTV.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    
    chatScroll.documentView      = chatTV;
    self.chatTextView            = chatTV;

    // Put both panes into the split view;
    BOOL showRight = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowUserlistOnRightSide"];
   
    if(showRight) {
        [splitView addArrangedSubview:chatPane];
        [splitView addArrangedSubview:userScroll];
    }
    
    else {
        [splitView addArrangedSubview:userScroll];
        [splitView addArrangedSubview:chatPane];
    }

    // ensure the user-list pane holds its width and chat expands
    // (the widthAnchor on userScroll already fixes it; this boosts its holding priority)
    NSInteger userIndex = showRight ? 1 : 0;
    [splitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:userIndex];

    // Build the bottom input row
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSZeroRect];
    input.translatesAutoresizingMaskIntoConstraints = NO;
    input.target            = self;
    input.action            = @selector(onSend:);
    ((NSTextFieldCell*)input.cell).sendsActionOnEndEditing = YES;
    [chatPane addSubview:input];
    self.messageField = input;

    NSButton *sendBtn = [[NSButton alloc] initWithFrame:NSZeroRect];
    sendBtn.translatesAutoresizingMaskIntoConstraints = NO;
    sendBtn.bezelStyle = NSBezelStyleSmallSquare;
    sendBtn.title      = @"Send";
    sendBtn.target     = self;
    sendBtn.action     = @selector(onSend:);
    [chatPane addSubview:sendBtn];
    self.sendButton = sendBtn;
    
    BOOL showSendButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowChatSendButton"];
        
    if(showSendButton) {
        self.sendButton.hidden = NO;
    }
        
    else {
        self.sendButton.hidden = YES;
    }
    
    // build both possible trailing constraints for `input`
    NSLayoutConstraint *inputToButton = [input.trailingAnchor
        constraintEqualToAnchor:sendBtn.leadingAnchor
                         constant:-8];

    NSLayoutConstraint *inputToPane   = [input.trailingAnchor
        constraintEqualToAnchor:chatPane.trailingAnchor
                         constant:-10];

    // now activate only the one we need
    if (showSendButton) {
        inputToButton.active = YES;
        inputToPane.active   = NO;
    } else {
        inputToButton.active = NO;
        inputToPane.active   = YES;
    }

    // Auto-Layout the scroll view + input row (but NOT the textView)
    [NSLayoutConstraint activateConstraints:@[
      // chatScroll around top & above input
      [chatScroll.topAnchor      constraintEqualToAnchor:chatPane.topAnchor    constant:10],
      [chatScroll.leadingAnchor  constraintEqualToAnchor:chatPane.leadingAnchor  constant:10],
      [chatScroll.trailingAnchor constraintEqualToAnchor:chatPane.trailingAnchor constant:-10],
      [chatScroll.bottomAnchor   constraintEqualToAnchor:input.topAnchor       constant:-10],

      // input row
      [input.leadingAnchor    constraintEqualToAnchor:chatPane.leadingAnchor  constant:10],
      [input.bottomAnchor     constraintEqualToAnchor:chatPane.bottomAnchor   constant:-10],
      [input.heightAnchor     constraintEqualToConstant:48],

      // send button
      [sendBtn.trailingAnchor constraintEqualToAnchor:chatPane.trailingAnchor constant:-10],
      [sendBtn.centerYAnchor  constraintEqualToAnchor:input.centerYAnchor],
      [sendBtn.widthAnchor    constraintEqualToConstant:60],
      [sendBtn.heightAnchor   constraintEqualToConstant:48],
    ]];
    
    [self.chatTextView setEditable:YES];
    [self.chatTextView.textStorage setAttributedString:self.cachedChatContents];
    [self.chatTextView checkTextInDocument:nil];
    [self.chatTextView scrollToEndOfDocument:self];
    [self.chatTextView setEditable:NO];
    
    [self.window makeFirstResponder:self.messageField];
    
    [self.userListView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
    //NSLog(@"[DEBUG] numberOfRowsInTableView called, users = %@", self.users);
    
    if(tv == self.userListView) {
        return self.users.count;
    }
    
    else if(tv == self.filesTableView) {
        return self.filesModel.count;
    }
    
    return 0;
}

- (NSView*)tableView:(NSTableView*)tv
   viewForTableColumn:(NSTableColumn*)col
                  row:(NSInteger)row
{
    if(tv == self.userListView) {
        
        // Ask for—or create—a reusable cell
        NSTableCellView *cell = [tv makeViewWithIdentifier:@"nickCell" owner:self];
        if (!cell) {
            cell = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
            cell.identifier = @"nickCell";
            
            // — imageView on the left
            NSImageView *iv = [[NSImageView alloc] initWithFrame:NSZeroRect];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            iv.imageScaling = NSImageScaleProportionallyDown;
            [cell addSubview:iv];
            cell.imageView = iv;
            
            // — textField to the right
            NSTextField *tf = [[NSTextField alloc] initWithFrame:NSZeroRect];
            tf.bezeled         = NO;
            tf.drawsBackground = NO;
            tf.editable        = NO;
            tf.selectable      = NO;
            tf.translatesAutoresizingMaskIntoConstraints = NO;
            [cell addSubview:tf];
            cell.textField = tf;
            
            // — layout
            [NSLayoutConstraint activateConstraints:@[
                // imageView stays centered vertically at 16×16
                [iv.leadingAnchor    constraintEqualToAnchor:cell.leadingAnchor constant:2],
                [iv.centerYAnchor    constraintEqualToAnchor:cell.centerYAnchor],
                [iv.widthAnchor      constraintEqualToConstant:16],
                [iv.heightAnchor     constraintEqualToConstant:16],
                
                // textField leading/trailing as before…
                [tf.leadingAnchor    constraintEqualToAnchor:iv.trailingAnchor constant:4],
                [tf.trailingAnchor   constraintEqualToAnchor:cell.trailingAnchor constant:-5],
                // …but now centre it vertically
                [tf.centerYAnchor    constraintEqualToAnchor:cell.centerYAnchor],
            ]];
        }
        
        // Populate
        NSDictionary *u = self.users[row];
        cell.textField.stringValue = u[@"nick"] ?: @"";
        
        // Icon logic
        NSString *iconNumberStr = [u[@"icon"] stringValue];
        NSString *iconNumberFilename;
        NSDictionary *iconFilenamesDict = [UserIcons standardUserIconsDict];
        
        if(iconFilenamesDict[iconNumberStr] == NULL) {
            iconNumberFilename = @"148.User.png";
        }
        
        else {
            iconNumberFilename = iconFilenamesDict[iconNumberStr];
        }
        
        if(iconNumberFilename) {
            cell.imageView.image  = [NSImage imageNamed:iconNumberFilename];
            cell.imageView.hidden = NO;
        }
        
        else {
            cell.imageView.hidden = YES;
        }
        
        // Color by status (unchanged)
        NSInteger status = [u[@"status"] integerValue];
        switch (status) {
            case 0: cell.textField.textColor = [NSColor textColor]; break;
            case 1: cell.textField.textColor = [NSColor disabledControlTextColor]; break;
            case 2: cell.textField.textColor = [NSColor colorWithHexString:@"E10101"]; break;
            default:cell.textField.textColor = [NSColor colorWithHexString:@"#831E1C"]; break;
        }
        
        return cell;
    }
    
    else if(tv == self.filesTableView) {
        NSDictionary *entry    = self.filesModel[row];
            NSString     *ident    = col.identifier;
            // Ask NSTableView for a recycled view with this identifier:
            NSTableCellView *cell  = [tv makeViewWithIdentifier:ident owner:self];
            if (!cell) {
                // None to recycle → create a fresh one
                cell = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
                cell.identifier = ident;

                if ([ident isEqualToString:@"icon"]) {
                    // image view centered
                    NSImageView *iv = [[NSImageView alloc] initWithFrame:NSZeroRect];
                    iv.translatesAutoresizingMaskIntoConstraints = NO;
                    iv.imageScaling = NSImageScaleProportionallyUpOrDown;
                    [cell addSubview:iv];
                    cell.imageView = iv;
                    [NSLayoutConstraint activateConstraints:@[
                        [iv.centerXAnchor constraintEqualToAnchor:cell.centerXAnchor],
                        [iv.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
                        [iv.widthAnchor  constraintEqualToConstant:16],
                        [iv.heightAnchor constraintEqualToConstant:16],
                    ]];
                } else {
                    // a simple label
                    NSTextField *tf = [[NSTextField alloc] initWithFrame:NSZeroRect];
                    tf.translatesAutoresizingMaskIntoConstraints = NO;
                    tf.bezeled          = NO;
                    tf.drawsBackground  = NO;
                    tf.editable         = NO;
                    tf.selectable       = NO;
                    [cell addSubview:tf];
                    cell.textField = tf;
                    [NSLayoutConstraint activateConstraints:@[
                        [tf.leadingAnchor  constraintEqualToAnchor:cell.leadingAnchor constant:5],
                        [tf.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-5],
                        [tf.centerYAnchor  constraintEqualToAnchor:cell.centerYAnchor],
                    ]];
                }
            }

            // Populate from your model:
            if ([ident isEqualToString:@"icon"]) {
                cell.imageView.image = entry[@"icon"];
            }
            else if ([ident isEqualToString:@"name"]) {
                cell.textField.stringValue = entry[@"name"];
                cell.textField.lineBreakMode = NSLineBreakByTruncatingTail;
                cell.textField.cell.wraps = NO;
                cell.textField.cell.truncatesLastVisibleLine = YES;
            }
        
            else if ([ident isEqualToString:@"kind"]) {
                cell.textField.stringValue = entry[@"kind"];
                cell.textField.lineBreakMode = NSLineBreakByTruncatingTail;
                cell.textField.cell.wraps = NO;
                cell.textField.cell.truncatesLastVisibleLine = YES;
            }
        
            else if ([ident isEqualToString:@"size"]) {
                cell.textField.stringValue = entry[@"size"];
                cell.textField.lineBreakMode = NSLineBreakByTruncatingTail;
                cell.textField.cell.wraps = NO;
                cell.textField.cell.truncatesLastVisibleLine = YES;
            }
        
        return cell;
    }
    
    return nil;
}

#pragma mark - News UI

- (void)buildNewsUI {
    
    NSView *root = self.window.contentView;

    // Create the themed background wrapper
    ThemedBackgroundView *bg = [[ThemedBackgroundView alloc] initWithFrame:NSZeroRect];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:bg];
    [NSLayoutConstraint activateConstraints:@[
      [bg.leadingAnchor  constraintEqualToAnchor:root.leadingAnchor],
      [bg.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
      [bg.topAnchor      constraintEqualToAnchor:root.topAnchor],
      [bg.bottomAnchor   constraintEqualToAnchor:root.bottomAnchor],
    ]];

    // Now build *inside* bg instead of root

    // Scroll view
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.hasVerticalScroller   = YES;
    scroll.hasHorizontalScroller = YES;
    scroll.borderType            = NSNoBorder;
    [bg addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor  constraintEqualToAnchor:bg.leadingAnchor constant:10],
        [scroll.trailingAnchor constraintEqualToAnchor:bg.trailingAnchor constant:-10],
        [scroll.topAnchor      constraintEqualToAnchor:bg.topAnchor constant:10],
        [scroll.bottomAnchor   constraintEqualToAnchor:bg.bottomAnchor constant:-10],
    ]];
    self.newsScrollView = scroll;

    // The text view
    CGFloat initialWidth = NSWidth(root.bounds) - 20;
    NSTextView *tv = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, initialWidth, 500)];
    tv.minSize               = NSMakeSize(0,0);
    tv.maxSize               = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    tv.verticallyResizable   = YES;
    tv.horizontallyResizable = NO;
    tv.autoresizingMask      = NSViewWidthSizable;
    tv.textContainerInset    = NSMakeSize(5,5);
    tv.textContainer.widthTracksTextView  = YES;
    tv.textContainer.heightTracksTextView = NO;
    tv.editable   = NO;
    tv.selectable = YES;
    tv.font       = [NSFont userFixedPitchFontOfSize:12];
    
    // turn on automatic link detection
    // this will scan the text and wrap anything that looks like http://… or https://… in an NSLink attribute
    tv.automaticLinkDetectionEnabled = YES;

    // only detect links (you can OR in other NSTextCheckingType bits if you like)
    tv.enabledTextCheckingTypes = NSTextCheckingTypeLink;

    scroll.documentView = tv;
    
    // Populate
    NSMutableString *allNews = [NSMutableString string];
    for (NSString *item in self.newsItems) {
        [allNews appendFormat:@"%@\n", item];
    }
    
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.lineHeightMultiple = 1.25;
    ps.paragraphSpacing    = 0.0;     // no extra paragraph‐to‐paragraph gap
    ps.paragraphSpacingBefore = 0;

    // Make your attributes
    NSDictionary *attrs = @{
        NSParagraphStyleAttributeName: ps,
        NSFontAttributeName:          tv.font ?: [NSFont userFixedPitchFontOfSize:12],
        NSForegroundColorAttributeName: [NSColor textColor]
    };

    // Apply to existing text
    NSAttributedString *newText =
      [[NSAttributedString alloc] initWithString:allNews
                                      attributes:attrs];

    // So new typing uses the same style:
    tv.defaultParagraphStyle = ps;
    tv.typingAttributes      = attrs;
    
    
    [tv setEditable:YES];
    [tv.textStorage setAttributedString:newText];
    
    [tv checkTextInDocument:nil];
    [tv setEditable:NO];
    
    self.newsTextView = tv;
}

- (void)buildFilesUI {
    NSView *root = self.window.contentView;
    [root.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // Background container
    ThemedBackgroundView *bg = [[ThemedBackgroundView alloc] initWithFrame:NSZeroRect];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:bg];
    [NSLayoutConstraint activateConstraints:@[
        [bg.leadingAnchor  constraintEqualToAnchor:root.leadingAnchor],
        [bg.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [bg.topAnchor      constraintEqualToAnchor:root.topAnchor],
        [bg.bottomAnchor   constraintEqualToAnchor:root.bottomAnchor],
    ]];

    // Path control (breadcrumb) using custom pathItems
    self.pathControl = [[NSPathControl alloc] initWithFrame:NSZeroRect];
    
    self.pathControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.pathControl.pathStyle = NSPathStyleStandard;
    self.pathControl.target = self;
    self.pathControl.action = @selector(pathControlDidChange:);
    // build our own items array so root is “/”
   // pathControl.pathItems = [self pathItemsForURL:self.currentDirectoryURL];
    self.pathControl.pathItems = [self pathItemsForURL:[NSURL fileURLWithPath:self.filePath]];

    [bg addSubview:self.pathControl];
    [NSLayoutConstraint activateConstraints:@[
        [self.pathControl.leadingAnchor constraintEqualToAnchor:bg.leadingAnchor constant:10],
        [self.pathControl.trailingAnchor constraintEqualToAnchor:bg.trailingAnchor constant:-10],
        [self.pathControl.topAnchor constraintEqualToAnchor:bg.topAnchor constant:10],
        [self.pathControl.heightAnchor constraintEqualToConstant:22],
    ]];

    // Scroll view below the path control
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.hasVerticalScroller = YES;
    scroll.hasHorizontalScroller = YES;
    scroll.borderType = NSNoBorder;
    [bg addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor  constraintEqualToAnchor:bg.leadingAnchor  constant:10],
        [scroll.trailingAnchor constraintEqualToAnchor:bg.trailingAnchor constant:-10],
        [scroll.topAnchor      constraintEqualToAnchor:self.pathControl.bottomAnchor constant:8],
        [scroll.bottomAnchor   constraintEqualToAnchor:bg.bottomAnchor   constant:-10],
    ]];

    // Table view setup (unchanged)
    NSTableView *tv = [[NSTableView alloc] initWithFrame:NSZeroRect];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.delegate   = self;
    tv.dataSource = self;
    tv.target     = self;
    tv.doubleAction = @selector(filesTableViewDidDoubleClick:);
    //tv.rowHeight  = 32;
    tv.usesAlternatingRowBackgroundColors = true;
    tv.style = NSTableViewStyleFullWidth;

    // Icon column
    NSTableColumn *iconCol = [[NSTableColumn alloc] initWithIdentifier:@"icon"];
    iconCol.width = iconCol.minWidth = iconCol.maxWidth = 16;
    [iconCol setDataCell:[[NSImageCell alloc] init]];
    [tv addTableColumn:iconCol];

    // Name column
    NSTableColumn *nameCol = [[NSTableColumn alloc] initWithIdentifier:@"name"];
    //nameCol.title = @"Name"; nameCol.width = 500;
    nameCol.minWidth = 250;
    //nameCol.maxWidth = 800;
    [tv addTableColumn:nameCol];

    // Kind column
    NSTableColumn *kindCol = [[NSTableColumn alloc] initWithIdentifier:@"kind"];
    //kindCol.title = @"Kind"; kindCol.width = 200;
    kindCol.minWidth = 200;
    //kindCol.maxWidth = 500;
    //kindCol.maxWidth = 220;
    [tv addTableColumn:kindCol];

    // Size column
    NSTableColumn *sizeCol = [[NSTableColumn alloc] initWithIdentifier:@"size"];
    //sizeCol.title = @"Size"; sizeCol.width = 80;
    sizeCol.width = sizeCol.minWidth = sizeCol.maxWidth = 80;
    [tv addTableColumn:sizeCol];
    
    // Icon column never grows:
    iconCol.resizingMask = NSTableColumnNoResizing;

    // Name & Kind columns auto-resize with the table:
    nameCol.resizingMask = NSTableColumnAutoresizingMask;
    kindCol.resizingMask = NSTableColumnAutoresizingMask;

    // Size column is fixed unless the user drags it:
    sizeCol.resizingMask = NSTableColumnNoResizing;
    //sizeCol.

    scroll.documentView = tv;
    self.filesTableView = tv;
    
    self.filesTableView.intercellSpacing = NSMakeSize(0, 0);
    self.filesTableView.columnAutoresizingStyle = NSTableViewReverseSequentialColumnAutoresizingStyle;
    
    [self.filesTableView setHeaderView:nil];

    // Load the initial directory contents
    //[self loadFilesInDirectory:self.currentDirectoryURL];
    [tv reloadData];
}

// Helper to build pathItems from a URL so that the very first component is “/”
- (NSArray<NSPathControlItem*>*)pathItemsForURL:(NSURL*)dirURL {
    // Split on “/” and include the leading “/” as the first component
    NSArray<NSString*> *comps = [dirURL.path pathComponents];
    NSMutableArray<NSPathControlItem*> *items = [NSMutableArray array];
    NSURL *accum = [NSURL URLWithString:@"/"];

    for (NSString *comp in comps) {
        NSPathControlItem *item = [NSPathControlItem new];
        
        // rebuild each sub-URL:
        accum = [accum URLByAppendingPathComponent:comp isDirectory:YES];
        [item setValue:accum forKey:@"URL"];
       
        // show literally “/” for root, else the folder name
        item.title = [comp isEqualToString:@"/"] ? @"Root" : comp;
        [items addObject:item];
    }
    return items;
}

// Update when the user clicks a breadcrumb
- (void)pathControlDidChange:(NSPathControl*)sender {
    NSURL *clicked = sender.clickedPathItem.URL;
    if (!clicked) return;
    self.filePath = [clicked path];
    // rebuild the breadcrumb to reflect the new root
    sender.pathItems = [self pathItemsForURL:clicked];
    
    [self.filesModel removeAllObjects];
    
    //[self.transactions sendGetFileNameListTransactionWithFolder:self.filePath forStream:self.outputStream];
    
    if([self cachedDirectoryListingForPath:self.filePath] != nil) {
        //NSLog(@"Using cached listing for %@", self.filePath);
        [self.filesModel addObjectsFromArray:[self cachedDirectoryListingForPath:self.filePath]];
    }
    
    else {
        //NSLog(@"Using live listing for %@", self.filePath);
        [self.transactions sendGetFileNameListTransactionWithFolder:self.filePath forStream:self.outputStream];
    }
    
    [self.filesTableView reloadData];
}

- (void)filesTableViewDidDoubleClick:(id)sender {    
    NSInteger row = self.filesTableView.clickedRow;
    if (row < 0) return;
    NSDictionary *entry = self.filesModel[row];
    
    //Download file else change directories
    if(![entry[@"type"] isEqualToString:@"fldr"]) {
        self.downloadFilename = entry[@"name"];
        [self.transactions sendDownloadFileTransactionWithName:self.downloadFilename inFolder:self.filePath stream:self.outputStream];
        return;
    }
        
    if([self.filePath isEqualToString:@"/"] ) {
        self.filePath = [NSString stringWithFormat:@"%@%@", self.filePath, entry[@"name"]];
    }
    
    else {
        self.filePath = [NSString stringWithFormat:@"%@/%@", self.filePath, entry[@"name"]];
    }
        
    //NSLog(@"self.filePath: %@", self.filePath);
        
    if([self cachedDirectoryListingForPath:self.filePath] != nil) {
        //NSLog(@"Using cached listing for %@", self.filePath);
        [self.filesModel removeAllObjects];
        [self.filesModel addObjectsFromArray:[self cachedDirectoryListingForPath:self.filePath]];
        [self.filesTableView reloadData];
    }
    
    else {
        //Folder is empty so display empty folder
        if([entry[@"size"] isEqualToString:@"0 files"]) {
            [self.filesModel removeAllObjects];
            [self.filesTableView reloadData];
        }
        
        //Get folder listing
        else {            
            //NSLog(@"Using live listing for %@", self.filePath);
            [self.transactions sendGetFileNameListTransactionWithFolder:self.filePath forStream:self.outputStream];
        }
    }
    
    self.pathControl.pathItems = [self pathItemsForURL:[NSURL fileURLWithPath:self.filePath]];
}

-  (NSMutableArray<NSDictionary *> *)cachedDirectoryListingForPath:(NSString *)path {
    // Check if the path is cached
    NSMutableArray<NSDictionary *> *cachedListing = self.directoryCache[path];
        
    if (cachedListing) {
        // Return the cached listing
        return cachedListing;
    } else {
        return nil;
    }
}

#pragma mark - Connect & Protocol

- (void)onConnect:(id)sender {
    //NSLog(@"onConnect");
    
    self.iconNumber = (uint32_t)[[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultIcon"];
    
    NSArray<NSString *> *components = [self.serverField.textField.stringValue componentsSeparatedByString:@":"];
           
   if (components.count > 0) {
       self.serverAddress = components[0]; // The hostname
   }
   
    if (components.count > 1) {
        self.serverPort = components[1].intValue; // The port number
    }
    
    else {
        self.serverPort = 5500;
    }

    NSError *readError = nil;
    NSURL *chatFileURL = [NSURL fileURLWithPath:[[AppSupport chatsURL].path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.rtf", self.serverAddress]]];
    
    NSAttributedString *oldChat = [NSAttributedString attributedStringWithRTFFileURL:chatFileURL
                                                                                    error:&readError];
    if (!oldChat) {
        NSLog(@"❌ Failed to load RTF: %@", readError.localizedDescription);
    } else {
        NSLog(@"✅ Loaded RTF; length = %lu", (unsigned long)oldChat.length);
        [self.cachedChatContents setAttributedString:oldChat];
    }
    
    // Open streams & start handshake
    [self connectToHost:self.serverAddress port:self.serverPort];
    
    self.login = self.loginField.stringValue;
    self.password = self.passwordField.stringValue;
    self.nickname = self.nickField.stringValue;
}

- (void)_networkThreadEntryPoint {
    @autoreleasepool {
        // Add a “dummy” port or source so the run loop doesn’t exit immediately.
        // Without any input source, `-run` would return instantly.
        [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];

        // Now spin the run loop forever.
        // It will return only if the thread is cancelled or run loop is explicitly stopped.
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)onDisconnect:(id)sender {
    [self stopUserListTimer];
    
    //Reset agreement message toggle on disconnect
    self.showAgreementMessage = YES;
    
    [self.servers removeAllObjects];

    [self.cachedChatContents setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    
    [self performSelector:@selector(_closeStreams)
                 onThread:self.networkThread
               withObject:nil
            waitUntilDone:NO];
    
    [self.networkThread cancel];
    
    self.isReconnecting = NO;
    
    // Reset protocol state
    self.handshakeState = HandshakeStateWaitingForHello;
    self.awaitingOpenUser = NO;
    self.awaitingModifyReply = NO;
    
    self.canDownloadFile = NO;
    self.canDownloadFolder = NO;
    self.canUploadFile = NO;
    self.canUploadFolder = NO;
    self.canReadNews = NO;
    self.canPostNews = NO;
    
    self.processUserListCalled = NO;
    self.hasReceivedInitialUserList = NO;
    [self.users removeAllObjects];
    
    self.processNewsCalled = NO;
    self.hasReceivedInitialNews = NO;
    [self.newsItems removeAllObjects];
    
    [self.filesModel removeAllObjects];
    
    // Remove toolbar
    [self.window setToolbar:nil];
    
    [self.window close];
}

- (void)_closeStreams {
    // Runs on networkThread:
    if (self.inputStream) {
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream.delegate = nil;
        self.inputStream = nil;
    }
    if (self.outputStream) {
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream.delegate = nil;
        self.outputStream = nil;
    }
}

- (void)onReconnect {
    //Don't show agreement message because of reconnect
    self.showAgreementMessage = NO;
    
    [self performSelector:@selector(_closeStreams)
                 onThread:self.networkThread
               withObject:nil
            waitUntilDone:NO];
        
    // Reset protocol state
    self.handshakeState = HandshakeStateWaitingForHello;
    self.awaitingOpenUser = NO;
    self.awaitingModifyReply = NO;
    
    self.canDownloadFile = NO;
    self.canDownloadFolder = NO;
    self.canUploadFile = NO;
    self.canUploadFolder = NO;
    self.canReadNews = NO;
    self.canPostNews = NO;
    
    self.processUserListCalled = NO;
    self.hasReceivedInitialUserList = NO;
    [self.users removeAllObjects];
    
    self.processNewsCalled = NO;
    self.hasReceivedInitialNews = NO;
    [self.newsItems removeAllObjects];
    
    [self.filesModel removeAllObjects];
    
    // Open streams & start handshake
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self connectToHost:self.serverAddress port:self.serverPort];
        self.isReconnecting = NO;
    });
}

- (void) windowWillClose:(NSNotification *) notification
{
    AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
    [appDel removeClient:self.uuid];
    [appDel tileAllWindows];
    
    self.uuid = nil;
    self.servers = nil;
    
    self.cachedChatContents = nil;
    self.transactions = nil;
    
    self.users = nil;
    self.newsItems = nil;
    self.filesModel = nil;
    
    self.serverAgreementMessage = nil;
    self.serverAddress = nil;
    self.networkThread = nil;
    
    //self.window = nil;
    self.connectionWindow = nil;
    self.nickSheetWindow = nil;
    self.broadcastSheetWindow = nil;
    self.newsPostSheetWindow = nil;
    self.agreementSheetWindow = nil;
    
    self.serverField = nil;
    self.loginField = nil;
    self.nickField = nil;
    self.iconField = nil;
    self.bookmarkMenu = nil;
    self.passwordField = nil;
    self.connectButton = nil;
    
    self.splitView = nil;
    self.chatScrollView = nil;
    self.chatTextView = nil;
    self.userListView = nil;
    self.messageField = nil;
    self.sendButton = nil;
    
    self.newsScrollView = nil;
    self.newsTextView = nil;
    
    self.nickname = nil;
    self.login = nil;
    self.password = nil;
    
    self.openUserNick = nil;
    self.openUserLogin = nil;
    self.openUserPassword = nil;
}

- (void)windowDidResize:(NSNotification *)notification {
    [self redistributeTableColumnWidths];
}

- (void)redistributeTableColumnWidths {
    NSTableColumn *iconCol = [self.filesTableView tableColumnWithIdentifier:@"icon"];
    NSTableColumn *nameCol = [self.filesTableView tableColumnWithIdentifier:@"name"];
    NSTableColumn *typeCol = [self.filesTableView tableColumnWithIdentifier:@"type"];
    NSTableColumn *sizeCol = [self.filesTableView tableColumnWithIdentifier:@"size"];

    // total width available for all three columns
    CGFloat total = self.filesTableView.bounds.size.width;

    // subtract off your frozen "icon" and “size” columns
    CGFloat fixed = iconCol.width + sizeCol.width;
    CGFloat leftover = MAX(0, total - fixed);

    // enforce minimums
    CGFloat minName = nameCol.minWidth;
    CGFloat minType = typeCol.minWidth;

    // weights: name gets 2 parts, type gets 1 part
    CGFloat wName = 2.0, wType = 1.0, sumW = wName + wType;
    CGFloat newName = floor(leftover * (wName / sumW));
    CGFloat newType = leftover - newName;

    // clamp to minimums
    if (newName < minName) newName = minName;
    if (newType < minType) newType = minType;

    nameCol.width = newName;
    typeCol.width = newType;
}

- (void)connectToHost:(NSString *)host port:(uint16_t)port {
    CFReadStreamRef  r;
    CFWriteStreamRef w;
    CFStreamCreatePairWithSocketToHost(NULL,
                                       (__bridge CFStringRef)host,
                                       port,
                                       &r,
                                       &w);
    
    self.inputStream  = (__bridge_transfer NSInputStream *)r;
    self.outputStream = (__bridge_transfer NSOutputStream *)w;
    self.inputStream.delegate  = self;
    self.outputStream.delegate = self;
    
    [self performSelector:@selector(_scheduleAndOpenStreams)
                     onThread:self.networkThread
                   withObject:nil
                waitUntilDone:NO];
        
    self.handshakeState = HandshakeStateWaitingForHello;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create and configure the view controller
        NSString *msg = [NSString stringWithFormat:@"Connecting to %@…", self.serverAddress];
        ConnectingViewController *vc = [[ConnectingViewController alloc] initWithMessage:msg];

        // Create a sheet window
        self.connectingSheetWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,325,80)
                                                      styleMask:(NSWindowStyleMaskTitled)
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];
        self.connectingSheetWindow.contentViewController = vc;
        self.connectingSheetWindow.title                 = @"Please wait";


        // Begin sheet
        [self.connectionWindow beginSheet:self.connectingSheetWindow completionHandler:^(NSModalResponse returnCode) {
        }];
    });
}

- (void)_scheduleAndOpenStreams {
    // This code runs on "self.networkThread".
    // The run loop IS already spinning (because of -_networkThreadEntryPoint), so we can schedule streams here.

    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                 forMode:NSDefaultRunLoopMode];

    [self.inputStream open];
    [self.outputStream open];
}

#pragma mark – Protocol Handshake

- (uint16_t)getSocketForNick:(NSString*)nick {
    uint16_t socket = 0;
    
    NSUInteger idx = [self.users indexOfObjectPassingTest:^BOOL(NSDictionary *entry, NSUInteger i, BOOL *stop) {
        if([entry[@"nick"] isEqualToString:entry[@"nick"]]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if(idx != NSNotFound) {
        NSDictionary *entry =[self.users objectAtIndex:idx];
        return [entry[@"socket"] unsignedShortValue];
    }
    
    //Nickname not found
    return socket;
}

- (void)updateUserlistWithNick:(NSString*)newNick forSocket:(uint16_t)socketNumber {
    // Wrap the socket in an NSNumber for comparison
    NSNumber *sockNum = @(socketNumber);

    // Find the index of the existing user entry
    NSUInteger idx = [self.users indexOfObjectPassingTest:^BOOL(NSDictionary *entry, NSUInteger i, BOOL *stop) {
        return [entry[@"socket"] isEqualToNumber:sockNum];
    }];

    if (idx == NSNotFound) {
        NSLog(@"[WARN] Tried to update nick for unknown socket %u", socketNumber);
        return;
    }

    // Mutably copy the dictionary, update the nick, and put it back
    NSMutableDictionary *upd = [self.users[idx] mutableCopy];
    upd[@"nick"] = newNick;
    self.users[idx] = upd;

    // Reload just that one row in the table
    NSIndexSet *rows = [NSIndexSet indexSetWithIndex:idx];
    NSIndexSet *cols = [NSIndexSet indexSetWithIndex:0]; // assuming single‐column
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[DEBUG] Reloading userListView, users = %@", self.users);
        [self.userListView reloadDataForRowIndexes:rows columnIndexes:cols];
    });
    
    self.nickname = newNick;
}

// You’ll want to define this at the top of the file (or in a constants header)
//static const uint16_t OID_LOGIN = 105;  // adjust if your protocol uses a different object ID

/*- (void)sendOpenUserTransaction:(NSString*)login forStream:(NSOutputStream *)stream {
    self.awaitingOpenUser = YES;
    self.lastOpenLogin    = [login copy];  // stash it

    // plain UTF-8, no XOR
    NSData   *utf8     = [login dataUsingEncoding:NSUTF8StringEncoding];
    uint16_t  lenBE    = htons((uint16_t)utf8.length);
    uint16_t  oidBE    = htons(105);
    uint16_t  cntBE    = htons(1);

    NSMutableData *payload = [NSMutableData data];
    [payload appendBytes:&cntBE length:2];
    [payload appendBytes:&oidBE length:2];
    [payload appendBytes:&lenBE length:2];
    [payload appendData:utf8];
    
    // DEBUG: inspect each object in the payload
    {
      const uint8_t *p = payload.bytes;
      uint16_t count = ntohs(*(uint16_t*)p); p += 2;
      NSLog(@"[DEBUG] TX352 payload has %u object(s):", count);
      for (int i = 0; i < count; i++) {
        uint16_t oid = ntohs(*(uint16_t*)p); p += 2;
        uint16_t len = ntohs(*(uint16_t*)p); p += 2;
        NSData *obj = [NSData dataWithBytes:p length:len];
        p += len;

        // hex dump
        NSMutableString *hex = [NSMutableString stringWithCapacity:len*3];
        const uint8_t *bytes = obj.bytes;
        for (int b = 0; b < len; b++) {
          [hex appendFormat:@"%02x ", bytes[b]];
        }
        NSLog(@"[DEBUG]   OBJ %d → OID=%u, len=%u, raw=[%@]", i, oid, len, hex);

        // decode text
        NSString *s = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        NSLog(@"[DEBUG]       decoded → \"%@\"", s);
      }
    }

    // header
    uint8_t   flags = 0, rep = 0;
    uint16_t  typeBE = htons(352);
    uint32_t  txidBE = htonl(self.nextTxID++);
    uint32_t  errBE  = 0;
    uint32_t  szBE   = htonl((uint32_t)payload.length);

    NSMutableData *pkt = [NSMutableData data];
    [pkt appendBytes:&flags  length:1];
    [pkt appendBytes:&rep    length:1];
    [pkt appendBytes:&typeBE length:2];
    [pkt appendBytes:&txidBE length:4];
    [pkt appendBytes:&errBE  length:4];
    [pkt appendBytes:&szBE   length:4];
    [pkt appendBytes:&szBE   length:4];
    [pkt appendData:payload];

    NSLog(@"[DEBUG] → TX352 OpenUser(login=\"%@\")", login);
    [stream write:pkt.bytes maxLength:pkt.length];
}

- (void)sendModifyUserPrivilegesWithMask:(uint64_t)newPrivMask forStream:(NSOutputStream *)stream {
    // Build the payload header: 4 objects
    NSMutableData *payload = [NSMutableData data];
    uint16_t objCountBE = htons(4);
    [payload appendBytes:&objCountBE length:2];

    // Helper to append any OID + its raw data
    void (^appendOID)(uint16_t oid, NSData *d) = ^(uint16_t oid, NSData *d) {
        uint16_t oidBE = htons(oid);
        uint16_t lenBE = htons((uint16_t)d.length);
        [payload appendBytes:&oidBE length:2];
        [payload appendBytes:&lenBE length:2];
        [payload appendData:d];
    };

    // --- OID 102: nick (plain UTF-8) ---
    NSData *nickData = [self.openUserNick ?: @"" dataUsingEncoding:NSUTF8StringEncoding];
    appendOID(102, nickData);

    // --- OID 105: login (XOR-encoded) ---
    NSData *rawLogin = [self.openUserLogin ?: @"" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *encLogin = [rawLogin mutableCopy];
    uint8_t *loginBytes = encLogin.mutableBytes;
    for (NSUInteger i = 0; i < encLogin.length; i++) {
        loginBytes[i] ^= 0xFF;
    }
    appendOID(105, encLogin);

    // --- OID 106: password (NUL if unchanged, else UTF-8) ---
    NSData *pwBytes = [self passwordBytesForModify];  // helper returns NUL or UTF-8
    appendOID(106, pwBytes);

    // --- OID 110: priv-mask (8 bytes, BE bit order) ---
    uint8_t privBytes[8] = {0};
    for (NSUInteger bit = 0; bit < 38; bit++) {
        if ((newPrivMask >> bit) & 1ULL) {
            NSUInteger idx = bit / 8;
            NSUInteger pos = 7 - (bit % 8);
            privBytes[idx] |= (1 << pos);
        }
    }
    appendOID(110, [NSData dataWithBytes:privBytes length:8]);

    // --- DEBUG: Dump each object with raw bytes and decoded string ---
    NSData *dbgPayload = [payload copy];
    const uint8_t *ptr = dbgPayload.bytes;
    uint16_t cnt = ntohs(*(uint16_t*)ptr);
    ptr += 2;
    NSLog(@"[DEBUG] TX353 payload has %u objects:", cnt);
    for (int i = 0; i < cnt; i++) {
        uint16_t oid = ntohs(*(uint16_t*)ptr); ptr += 2;
        uint16_t len = ntohs(*(uint16_t*)ptr); ptr += 2;
        NSData *objData = [NSData dataWithBytes:ptr length:len];
        ptr += len;
        // hex dump
        NSMutableString *hex = [NSMutableString stringWithCapacity:len*3];
        const uint8_t *bytes = objData.bytes;
        for (int b = 0; b < len; b++) {
            [hex appendFormat:@"%02x ", bytes[b]];
        }
        NSLog(@"[DEBUG]   OBJ %d → OID=%u, len=%u, raw=[%@]", i, oid, len, hex);
        // decoded text for text OIDs
        if (oid == 102 || oid == 105 || oid == 106) {
            NSData *decoded;
            if (oid == 105) {
                // undo XOR for login
                NSMutableData *m = [objData mutableCopy];
                uint8_t *db = m.mutableBytes;
                for (NSUInteger x = 0; x < m.length; x++) db[x] ^= 0xFF;
                decoded = [m copy];
            } else {
                decoded = objData;
            }
            NSString *s = [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
            NSLog(@"[DEBUG]       decoded → '%@'", s);
        }
    }

    // Build TX353 header
    uint8_t  flags   = 0, rep = 0;
    uint16_t typeBE  = htons(353);
    uint32_t txidBE  = htonl(self.nextTxID++);
    uint32_t errBE   = 0;
    uint32_t sizeBE  = htonl((uint32_t)payload.length);

    NSMutableData *packet = [NSMutableData data];
    [packet appendBytes:&flags  length:1];
    [packet appendBytes:&rep    length:1];
    [packet appendBytes:&typeBE length:2];
    [packet appendBytes:&txidBE length:4];
    [packet appendBytes:&errBE  length:4];
    [packet appendBytes:&sizeBE length:4];
    [packet appendBytes:&sizeBE length:4];
    [packet appendData:payload];

    // Send it
    [stream write:packet.bytes maxLength:packet.length];

    // Refresh user record
    //self.awaitingOpenUser = YES;
    //[self sendOpenUserTransaction:self.lastOpenLogin];
}*/

/*- (void)toggleBroadcastAndPrivMsg {
    uint64_t oldMask = self.openUserPrivs;
    NSLog(@"[DEBUG] toggle: oldMask = 0x%016llx", (unsigned long long)oldMask);

    // flip both bits
    uint64_t bit19 = 1ULL<<19;
    uint64_t bit32 = 1ULL<<32;
    uint64_t newMask = oldMask ^ bit19 ^ bit32;

    NSLog(@"[DEBUG] toggle: newMask = 0x%016llx (bit19:%@, bit32:%@)",
          (unsigned long long)newMask,
          (newMask & bit19) ? @"ON" : @"OFF",
          (newMask & bit32) ? @"ON" : @"OFF");

    // stash login & send
    self.lastOpenLogin = [self.openUserLogin copy];
    [self sendModifyUserPrivilegesWithMask:newMask forStream:self.outputStream];

    // then immediately re-open
    self.awaitingOpenUser = YES;
    [self sendOpenUserTransaction:self.lastOpenLogin forStream:self.outputStream];
}*/

#pragma mark – Stream delegate

// Tracks whether we've received an automatic user list via TX354

// the single entry point for both streams
-  (void)stream:(NSStream*)s handleEvent:(NSStreamEvent)event {
    // ───    If we hit ErrorOccurred or EndEncountered on either stream,
    //        clean up & schedule a reconnect.
    if (event == NSStreamEventErrorOccurred || event == NSStreamEventEndEncountered) {
        NSError *err = [s streamError];
        if (event == NSStreamEventErrorOccurred) {
            NSLog(@"❌ Stream %@ reported error: %@", s == self.inputStream ? @"input" : @"output", err);
        } else {
            NSLog(@"🔌 Stream %@ was closed by peer", s == self.inputStream ? @"input" : @"output");
        }
        [self handleStreamDisconnection];
        return; // bail out, do not proceed to handshake or byte‐reading logic
    }

    // ───    If we’re still waiting for the server “Hello” and the outputStream is now writable,
    //        perform the handshake.
    if ( self.handshakeState == HandshakeStateWaitingForHello
      && s == self.outputStream
      && event == NSStreamEventHasSpaceAvailable )
    {
        [self performServerHandshake];
        return;
    }

    // ───    Otherwise, only process HasBytesAvailable on the inputStream.
    if (s != self.inputStream || event != NSStreamEventHasBytesAvailable) {
        return;
    }

    switch (self.handshakeState) {
        case HandshakeStateWaitingForLoginReply:
            [self handleLoginReply];
            break;
        case HandshakeStateConnected:
            [self handleConnectedStream];
            break;
        default:
            break;
    }
}

- (void)handleStreamDisconnection {
    NSLog(@"handleStreamDisconnection");
    
    [self stopUserListTimer];
    
    // If already in the process of reconnecting, do nothing.
    if (self.isReconnecting == NO) {
        // Mark that we are now “reconnecting” so we don’t schedule multiple timers
        self.isReconnecting = YES;
        NSLog(@"⏳ Disconnected – will attempt to reconnect in 3 seconds…");

        [self onReconnect];
    }
}

#pragma mark - Handshake Steps

- (void)performServerHandshake {
   // Build client hello (12 bytes)
   // “TRTP” + “HOTL” + uint16_t(minVer=1) + uint16_t(subVer=2)
   uint8_t hello[12];
   memcpy(hello,          "TRTPHOTL",  8);
   uint16_t minVer = htons(1), subVer = htons(2);
   memcpy(hello + 8, &minVer, 2);
   memcpy(hello + 10,&subVer, 2);

   // Send it, and check you wrote all 12 bytes
   NSInteger wrote = [self.outputStream write:hello maxLength:sizeof(hello)];
   if (wrote != sizeof(hello)) {
       NSLog(@"Handshake write failed: wrote %ld of %lu", (long)wrote, sizeof(hello));
       
       dispatch_async(dispatch_get_main_queue(), ^{
           [self onDisconnect:nil];
       });
       
       return;
   }

   // Read exactly 8 bytes back
   uint8_t resp[8] = {0};
   NSInteger  got = [self.inputStream read:resp maxLength:sizeof(resp)];
   if (got != sizeof(resp)) {
       NSLog(@"Handshake read failed: expected 8, got %ld", (long)got);
       
       dispatch_async(dispatch_get_main_queue(), ^{
           [self onDisconnect:nil];
       });
       
       return;
   }

   // Log the raw bytes so we can see what came back
   NSLog(@"[DEBUG] Server hello: %@", [NSString hexStringFromData:[NSData dataWithBytes:resp length:8]]);

   // Validate signature + error code
   if (memcmp(resp, "TRTP", 4) != 0) {
       NSLog(@"Handshake error: bad signature %.4s", resp);
       
       dispatch_async(dispatch_get_main_queue(), ^{
           [self onDisconnect:nil];
       });
       
       return;
   }
   uint32_t err = ntohl(*(uint32_t*)(resp + 4));
   if (err != 0) {
       NSLog(@"Server rejected handshake with code %u", err);
       
       dispatch_async(dispatch_get_main_queue(), ^{
           [self onDisconnect:nil];
       });
       
       return;
   }

   // Success → advance to login
    self.handshakeState = HandshakeStateWaitingForLoginReply;
    [self.transactions sendLoginTransactionWithNick:self.nickname iconNum:self.iconNumber Login:self.login Pass:self.password forStream:self.outputStream];
}

- (void)handleLoginReply {
    //NSLog(@"🔐 handleLoginReply");

    // read the 20-byte standard header
    static const NSUInteger kHeaderSize = 20;
    uint8_t hdr[kHeaderSize];
    NSUInteger gotHdr = 0;
    while (gotHdr < kHeaderSize) {
        NSInteger n = [self.inputStream read:hdr + gotHdr
                                  maxLength:kHeaderSize - gotHdr];
        if (n < 0) {
            NSLog(@"[DEBUG] Stream error reading login header: %@", self.inputStream.streamError);
            return;
        }
        if (n == 0) break;
        gotHdr += n;
    }
    if (gotHdr < kHeaderSize) {
        NSLog(@"[DEBUG] Incomplete login header: got %lu of %lu",
              (unsigned long)gotHdr, (unsigned long)kHeaderSize);
        return;
    }

    // parse + log each header field
    uint16_t txClass    = ntohs(*(uint16_t*)(hdr + 0));
    uint16_t txID       = ntohs(*(uint16_t*)(hdr + 2));
    uint32_t taskNumber = ntohl(*(uint32_t*)(hdr + 4));
    uint32_t errCode    = ntohl(*(uint32_t*)(hdr + 8));
    uint32_t payloadLen = ntohl(*(uint32_t*)(hdr + 12));

    NSLog(@"[DEBUG] login-reply header:");
    NSLog(@"   class    = %u",    txClass);
    NSLog(@"   ID       = %u",    txID);
    NSLog(@"   task#    = %u",    taskNumber);
    NSLog(@"   error    = %u %@", errCode,
          errCode==0 ? @"(OK)" : @"(FAIL)");
    NSLog(@"   dataLen  = %u",    payloadLen);
        
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window endSheet:self.connectingSheetWindow];

        if(errCode == 1) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Incorrect login"];
            [alert setInformativeText:@""];
            [alert addButtonWithTitle:@"OK"];
               
            // Show the alert
            [alert runModal];
            
            [self onDisconnect:nil];
        }
        
        else {
            [self transformToChatUI];
        }
    });

    // read the payload
    NSMutableData *body = [NSMutableData dataWithCapacity:payloadLen];
    NSUInteger gotBody = 0;
    uint8_t tmp[1024];
    while (gotBody < payloadLen) {
        NSUInteger chunk = MIN(sizeof(tmp), payloadLen - gotBody);
        NSInteger n = [self.inputStream read:tmp maxLength:chunk];
        if (n < 0) {
            NSLog(@"[DEBUG] Stream error reading login payload: %@", self.inputStream.streamError);
            return;
        }
        if (n == 0) break;
        [body appendBytes:tmp length:n];
        gotBody += n;
    }

    if (gotBody < payloadLen) {
        NSLog(@"[DEBUG] Incomplete login payload: got %lu of %u",
              (unsigned long)gotBody, payloadLen);
    } else {
        NSLog(@"[DEBUG] Full login payload received (%lu bytes)", (unsigned long)body.length);
    }

    // **extra debug** — dump both hex _and_ any UTF-8 string
    NSString *hexDump = [NSString hexStringFromData:body];
    NSLog(@"[DEBUG] login-payload (hex): %@", hexDump);

    NSString *textDump = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    if (textDump) {
        NSLog(@"[DEBUG] login-payload (UTF-8):\n%@", textDump);
    } else {
        NSLog(@"[DEBUG] login-payload (UTF-8): <non-UTF8 data>");
    }
    
    // extra debug: walk all objects
    const uint8_t *buf = (const uint8_t*)body.bytes;
    const uint8_t *end = buf + body.length;

    // now “p” is also a const uint8_t*
    const uint8_t *p = buf;

    // object-count
    if (body.length < 2) {
        NSLog(@"[DEBUG] login-payload too short");
    } else {
        uint16_t objCnt = CFSwapInt16BigToHost(*(uint16_t*)p);
        p += 2;
        NSLog(@"[DEBUG] login-payload contains %u objects:", objCnt);

        for (uint16_t i = 0; i < objCnt; i++) {
            // make sure we have room for the 4-byte header
            if (p + 4 > end) {
                NSLog(@"    ⚠️ incomplete header for object %u", i);
                break;
            }

            uint16_t oid  = CFSwapInt16BigToHost(*(uint16_t*)p); p += 2;
            uint16_t olen = CFSwapInt16BigToHost(*(uint16_t*)p); p += 2;

            // bounds-check the object payload
            if (p + olen > end) {
                NSLog(@"    ⚠️ object %u length %u overruns buffer", oid, olen);
                break;
            }

            NSData *objData = [NSData dataWithBytes:p length:olen];
            NSLog(@"    • OID=%u len=%u raw=%@", oid, olen, [NSString hexStringFromData:objData]);
            
            if (oid == 160) {
                uint16_t version = CFSwapInt16BigToHost(*(uint16_t*)p);
                NSLog(@"    • OID=160 len=%u protocolVersion=%u", olen, version);
                self.version = version;
            }
            
            if (oid == 161) {
                uint16_t bannerID = CFSwapInt16BigToHost(*(uint16_t*)p);
                NSLog(@"    • OID=161 len=%u bannerID=%u", olen, bannerID);
                self.bannerID = bannerID;
            }
            
            if (oid == 162) {
                NSString *name = [[NSString alloc]
                                  initWithBytes:p
                                         length:olen
                                       encoding:NSUTF8StringEncoding]
                                 ?: @"<binary>";
                NSLog(@"    • OID=162 len=%u serverName=\"%@\"", olen, name);
                self.serverName = name;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.window.title = [NSString stringWithFormat:@"%@ - %@", self.window.title, self.serverName];
                });
            }
            
            
            /*if (oid ==  {
                NSString *s = [[NSString alloc] initWithData:objData
                                                    encoding:NSUTF8StringEncoding];
                if (s) NSLog(@"        → as UTF-8: “%@”", s);
            }*/

            p += olen;
        }
    }

    /*BOOL needExplicitAgree = (txClass == 1 && txID == 0);
    if (needExplicitAgree) {
        NSLog(@"[DEBUG] Bare login-reply → sending explicit Agree");
        //[self.transactions sendAgreeTransactionWithLogin:self.login IconNum:self.iconNumber forStream:self.outputStream]; //Causes error but still logs on for hl.preterhuman.net
    } else {
        NSLog(@"[DEBUG] Agreement baked in → skipping explicit Agree");
    }*/
    
    if (txID == 354) {
        [self processUserPrivsPayload:body];
    }
    
    // finish handshake
    self.handshakeState = HandshakeStateConnected;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sendButton.enabled = YES;
    });
    
    [self scheduleInitialRequests];
}

- (void)startUserListTimer {
  // if one is already running, nuke it
  [self.userListTimer invalidate];
  self.userListTimer = [NSTimer scheduledTimerWithTimeInterval:30*60
                                                        target:self
                                                      selector:@selector(handleUserListTimer:)
                                                      userInfo:self.outputStream
                                                       repeats:YES];
}

- (void)stopUserListTimer {
  [self.userListTimer invalidate];
  self.userListTimer = nil;
}

- (void)handleUserListTimer:(NSTimer *)timer {
    
    NSOutputStream *stream = (NSOutputStream*)[timer userInfo];
    [self.transactions sendGetUserListTransactionForStream:stream];
}

- (void)scheduleInitialRequests {
    // just kick off the user-list; news will follow
        
    [self.transactions sendGetUserListTransactionForStream:self.outputStream];
    [self.transactions sendSetUserInfoTransactionWithNick:self.nickname iconNum:self.iconNumber forStream:self.outputStream];
    
    //self.downloadFilename = @"banner.jpg";
    //[self.transactions sendDownloadBannerTransactionForStream:self.outputStream]; //Causes error but still logs on for hl.preterhuman.net
    
    //Keep connection alive be sending userlist request
    [self startUserListTimer];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //self.downloadFilename = @"About This Area.txt";
        //[self.transactions sendGetFileInfoTransactionForName:self.downloadFilename inFolder:self.filePath stream:self.outputStream];
        //[self.transactions sendDownloadFileTransactionWithName:self.downloadFilename inFolder:self.filePath stream:self.outputStream];
        
        if(self.canReadNews) {
            [self.transactions sendGetNewsTransactionForStream:self.outputStream];
        }
        
        if(self.canDownloadFile || self.canUploadFile || self.canDownloadFolder || self.canUploadFolder) {
            [self.transactions sendGetFileNameListTransactionWithFolder:self.filePath forStream:self.outputStream];
        }
    });
}

#pragma mark - Connected State Handling

- (NSData*)readExactLength:(NSUInteger)length {
    if (length == 0) return [NSData data];
    NSMutableData *accum = [NSMutableData dataWithCapacity:length];
    NSUInteger remaining = length;
    while (remaining > 0) {
        uint8_t buf[4096];
        NSUInteger want = MIN(remaining, sizeof(buf));
        NSInteger got  = [self.inputStream read:buf maxLength:want];
        if (got < 0) {
            NSLog(@"[DEBUG] read error: %@", self.inputStream.streamError);
            return nil;
        } else if (got == 0) {
            // EOF or would‐block — keep trying
            continue;
        }
        [accum appendBytes:buf length:got];
        remaining -= got;
    }
    return accum;
}

- (void)handleConnectedStream {
    while ([self.inputStream hasBytesAvailable]) {
        static const NSUInteger kHeaderSize = 20;
        uint8_t hdr[kHeaderSize];
        NSUInteger gotHdr = 0;
        
        // Read header
        while (gotHdr < kHeaderSize) {
            NSInteger n = [self.inputStream read:hdr + gotHdr
                                      maxLength:kHeaderSize - gotHdr];
            if (n < 0) {
                NSLog(@"[DEBUG] Stream error reading header: %@", self.inputStream.streamError);
                return;
            }
            if (n == 0) {
                // no data right now—exit the inner loop and wait for the next event
                break;
            }
            gotHdr += n;
        }
        if (gotHdr < kHeaderSize) {
            // we simply didn't get the full header yet — try again later
            return;
        }
        
        uint16_t txType = ntohs(*(uint16_t*)(hdr + 2));
        uint32_t plen   = ntohl(*(uint32_t*)(hdr + 12));
        NSLog(@"[DEBUG] HEADER → txType=%u, payloadLen=%u", txType, plen);

        // Read the payload
        NSData *payload = [self readExactLength:plen];
        if (!payload || payload.length != plen) {
            NSLog(@"[DEBUG] Failed to read full payload: expected %u, got %lu",
                  plen, (unsigned long)(payload ? payload.length : 0));
            break;
        }

        // Dispatch based on packet type
        switch (txType) {
                
            case 0:
                // full-list, full-news, protocol version, filenames, errors, etc.
                [self debugTransactionZero:payload];
                break;

            case 102:
                // incremental news update
                [self processIncrementalNews:payload];
                break;
                
            case 354:
                // user privs
                [self processUserPrivsPayload:payload];
                break;

            default:
                [self processStandardTransaction:txType payload:payload];
                break;
        }
    }
}

#pragma mark - Debug Helpers

- (void)debugTransactionZero:(NSData *)pd {
    const uint8_t *bytes = pd.bytes;
    NSUInteger      L     = pd.length;
    if (L < 2) {
        NSLog(@"[DEBUG] TX0 too short for object‐count");
        return;
    }

    // pull off the object-count
    uint16_t objectCount = CFSwapInt16BigToHost(*(uint16_t*)(bytes + 0));
    NSLog(@"[DEBUG] RECEIVED TX 0 (%lu bytes), objectCount=%u: %@",
          (unsigned long)L, objectCount, [NSString hexStringFromData:pd]);
    
    BOOL sawFileList = NO;  // guard so we only call once

    // walk each object
    NSUInteger offset = 2;
    for (uint16_t i = 0; i < objectCount; i++) {
        if (offset + 4 > L) {
            NSLog(@"    ⚠️ incomplete object header at offset %lu", (unsigned long)offset);
            break;
        }

        uint16_t oid = CFSwapInt16BigToHost(*(uint16_t*)(bytes + offset));
        offset += 2;
        uint16_t len = CFSwapInt16BigToHost(*(uint16_t*)(bytes + offset));
        offset += 2;

        if (offset + len > L) {
            NSLog(@"    ⚠️ object %u length %u overruns buffer (%lu bytes left)",
                  oid, len, (unsigned long)(L - offset));
            break;
        }

        const uint8_t *objPtr = bytes + offset;

        switch (oid) {
            case 100: {
                NSString *errorMsg = [[NSString alloc]
                                  initWithBytes:objPtr
                                         length:len
                                       encoding:NSUTF8StringEncoding]
                                 ?: @"<binary>";
                NSLog(@"    • OID=100 len=%u errorMsg=\"%@\"", len, errorMsg);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert setMessageText:errorMsg];
                        [alert setInformativeText:@""];
                        [alert addButtonWithTitle:@"OK"];
                           
                        // Show the alert
                        [alert runModal];
                });
                
                
            } break;
                
            case 101: {
                if(self.processNewsCalled == NO) {
                    self.processNewsCalled = YES;
                    [self processFullNewsPayload:pd];
                }
                
            } break;

            case 110: {
                uint16_t privs = CFSwapInt16BigToHost(*(uint16_t*)objPtr);
                NSLog(@"    • OID=110 len=%u protocolVersion=%u", len, privs);
            } break;
                
            case 160: {
                uint16_t version = CFSwapInt16BigToHost(*(uint16_t*)objPtr);
                NSLog(@"    • OID=160 len=%u protocolVersion=%u", len, version);
                self.version = version;
            } break;

            case 161: {
                uint16_t bannerID = CFSwapInt16BigToHost(*(uint16_t*)objPtr);
                NSLog(@"    • OID=161 len=%u bannerID=%u", len, bannerID);
                self.bannerID = bannerID;
            } break;

            case 162: {
                NSString *name = [[NSString alloc]
                                  initWithBytes:objPtr
                                         length:len
                                       encoding:NSUTF8StringEncoding]
                                 ?: @"<binary>";
                NSLog(@"    • OID=162 len=%u serverName=\"%@\"", len, name);
                self.serverName = name;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.window.title = [NSString stringWithFormat:@"%@ - %@", self.window.title, self.serverName];
                });
                
            } break;

            case 200: { // File Name With Info
                if(!sawFileList) {
                    sawFileList = YES;
                    [self processFileListPayload:pd];
                }
                
            } break;
            
            case 107:
              [self processDownloadReply:pd];
              break;
                
            case 206:
              [self processFileInfoPayload:pd];
              break;

                
            case 300: {
                // user-list entry
                if(self.processUserListCalled == NO) {
                    self.processUserListCalled = YES;
                    [self processUserListPayload:pd];
                }
                
            } break;

            default: {
                NSData *d = [pd subdataWithRange:NSMakeRange(offset, len)];
                NSLog(@"    • OID=%u len=%u raw=%@", oid, len, [NSString hexStringFromData:d]);
            }
        }

        offset += len;
    }
}

- (void)processUserListPayload:(NSData*)payload {

    const uint8_t *b = payload.bytes;
    NSUInteger       L = payload.length;
    NSUInteger       p = 0;

    NSLog(@"📥 processUserListPayload – payloadLen = %lu", (unsigned long)L);

    // Need at least 2 bytes for the object count
    if (L < 2) {
        NSLog(@"⚠️ Too short for object count");
        return;
    }

    // Read how many objects are in this TX-0
    uint16_t objCount = CFSwapInt16BigToHost(*(uint16_t*)(b + p));
    p += 2;
    NSLog(@"    objectCount = %u", objCount);

    // Loop through each (ID,len,data) object
    for (NSUInteger i = 0; i < objCount; i++) {
        if (p + 4 > L) {
            NSLog(@"⚠️ Not enough bytes for object[%lu] header", (unsigned long)i);
            break;
        }

        uint16_t objectID  = CFSwapInt16BigToHost(*(uint16_t*)(b + p));  p += 2;
        uint16_t objectLen = CFSwapInt16BigToHost(*(uint16_t*)(b + p));  p += 2;
        NSLog(@"    object[%lu]: ID=%u, len=%u", (unsigned long)i, objectID, objectLen);

        if (p + objectLen > L) {
            NSLog(@"⚠️ object[%lu] overruns buffer, stopping", (unsigned long)i);
            break;
        }

        if (objectID == 300) {
            // ✅ This is our user-list object
            //sawUserListObject = YES;
            const uint8_t *o = b + p;
            NSUInteger      q = 0;

            // Parse socket, icon, status, nameLen
            uint16_t socketID = CFSwapInt16BigToHost(*(uint16_t*)(o + q)); q += 2;
            uint16_t icon     = CFSwapInt16BigToHost(*(uint16_t*)(o + q)); q += 2;
            uint16_t status   = CFSwapInt16BigToHost(*(uint16_t*)(o + q)); q += 2;
            uint16_t nameLen  = CFSwapInt16BigToHost(*(uint16_t*)(o + q)); q += 2;

            NSLog(@"      ➤ socket=%u, icon=%u, status=%u, nameLen=%u",
                  socketID, icon, status, nameLen);

            if (q + nameLen <= objectLen) {
                NSString *nick = [[NSString alloc] initWithBytes:o + q
                                                          length:nameLen
                                                        encoding:NSUTF8StringEncoding] ?: @"";
                NSLog(@"      ➤ nick = \"%@\"", nick);

                if(self.hasReceivedInitialUserList == NO) {
                    [self.users addObject:@{
                        @"socket": @(socketID),
                        @"icon":   @(icon),
                        @"status": @(status),
                        @"nick":   nick
                    }];
                }
            } else {
                NSLog(@"⚠️ nameLen overruns this object block");
            }
        } else {
            // Skip any other object (160,161,162,…)
            NSLog(@"      (skipping object %u)", objectID);
        }

        p += objectLen;
    }
    
    if(self.hasReceivedInitialUserList == NO) {
        self.hasReceivedInitialUserList = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.userListView reloadData];
        });
    }
}

- (void)processFullNewsPayload:(NSData*)payload {

  const uint8_t *bytes = payload.bytes;
  NSUInteger      len   = payload.length;
  NSUInteger      pos   = 0;

  if (len < 2) {
    NSLog(@"⚠️ payload too short (%lu)", (unsigned long)len);
    return;
  }

  // count
  uint16_t articleCount = CFSwapInt16BigToHost(*(uint16_t*)(bytes + pos));
  pos += 2;
  NSLog(@"📥 articleCount=%u payloadLen=%lu", articleCount, (unsigned long)len);

  if (articleCount < 1) {
    NSLog(@"⚠️ no articles");
  }
  else {
    // id + claimed-len
    if (pos + 4 > len) {
      NSLog(@"⚠️ not even room for article header");
    }
    else {
      pos += 2;                            // skip articleID entirely
      uint16_t textLen = CFSwapInt16BigToHost(*(uint16_t*)(bytes + pos));
      pos += 2;

      // clamp if the server lied
      if (pos + textLen > len) {
        NSLog(@"⚠️ claimed textLen=%u overruns buffer, clamping to %lu", textLen, (unsigned long)(len - pos));
        textLen = (uint16_t)(len - pos);
      }

      // pull the real bytes out
      NSData *chunk = [payload subdataWithRange:NSMakeRange(pos, textLen)];
      NSString *newsText = [[NSString alloc] initWithData:chunk
                                                 encoding:NSUTF8StringEncoding];
      if (! newsText) {
        // if even UTF-8 fails, try a fallback
        newsText = [[NSString alloc] initWithData:chunk
                                        encoding:NSISOLatin1StringEncoding] ?: @"";
      }

      NSLog(@"✅ got article (length=%u) → “%@…”", textLen,
            newsText.length>100 ? [newsText substringToIndex:100] : newsText);
        if(self.hasReceivedInitialNews == NO) {
            [self.newsItems addObject:newsText];
        }

      pos += textLen;
    }
  }

  // render
    if(self.hasReceivedInitialNews == NO) {
        self.hasReceivedInitialNews = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
          NSMutableString *all = [NSMutableString string];
          for (NSString *s in self.newsItems) [all appendFormat:@"%@\n",s];
          NSLog(@"📣 ALL NEWS = %@", all);
            
            NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
            ps.lineHeightMultiple = 1.25;
            ps.paragraphSpacing    = 0;     // no extra paragraph‐to‐paragraph gap
            ps.paragraphSpacingBefore = 0;

            // Make your attributes
            NSDictionary *attrs = @{
                NSParagraphStyleAttributeName: ps,
                NSFontAttributeName:          self.newsTextView.font ?: [NSFont userFixedPitchFontOfSize:12],
                NSForegroundColorAttributeName: [NSColor textColor]
            };

            // Apply to existing text
            NSAttributedString *newText =
              [[NSAttributedString alloc] initWithString:all
                                              attributes:attrs];

            // So new typing uses the same style:
            self.newsTextView.defaultParagraphStyle = ps;
            self.newsTextView.typingAttributes      = attrs;
            
            [self.newsTextView setEditable:YES];
            [self.newsTextView.textStorage setAttributedString:newText];
            [self.newsTextView checkTextInDocument:nil];
            [self.newsTextView setEditable:NO];
        });
    }
}

- (void)processFileListPayload:(NSData*)payload {
    const uint8_t *b = payload.bytes;
    NSUInteger       L = payload.length;
    NSUInteger       p = 0;

    NSLog(@"📥 processFileListPayload – payloadLen = %lu", (unsigned long)L);

    // Object‐count
    if (L < 2) {
        NSLog(@"⚠️ Too short for object count");
        return;
    }
    uint16_t objCount = CFSwapInt16BigToHost(*(uint16_t*)(b + p));
    p += 2;
    NSLog(@"    objectCount = %u", objCount);
    
    [self.filesModel removeAllObjects];

    // For each “file‐info” object
    for (NSUInteger i = 0; i < objCount; i++) {
        if (p + 4 > L) { break; }
        uint16_t objectID  = CFSwapInt16BigToHost(*(uint16_t*)(b + p));  p += 2;
        uint16_t objectLen = CFSwapInt16BigToHost(*(uint16_t*)(b + p));  p += 2;
        if (p + objectLen > L) { break; }

        if (objectID == 200) {
            const uint8_t *o = b + p;
            // parse type & creator (4 ASCII chars each)
            char type[5]   = { o[0], o[1], o[2], o[3], 0 };
            char creator[5]= { o[4], o[5], o[6], o[7], 0 };
            // 32-bit size
            uint32_t fsize = CFSwapInt32BigToHost(*(uint32_t*)(o + 8));
            // skip o+12..o+15 (reserved)
            // 16-bit script (often unused)
            uint16_t script = CFSwapInt16BigToHost(*(uint16_t*)(o + 16));
            // 16-bit name‐length
            uint16_t nameLen = CFSwapInt16BigToHost(*(uint16_t*)(o + 18));

            NSString *name = @"<malformed>";
            if (20 + nameLen <= objectLen) {
                name = [[NSString alloc]
                         initWithBytes:(o + 20)
                                length:nameLen
                              encoding:NSMacOSRomanStringEncoding]
                       ?: @"<non-UTF8>";
            }

            NSLog(@"    • File[%lu] type='%s' creator='%s' size=%u script=%u name=\"%@\"",
                  (unsigned long)i, type, creator, fsize, script, name);
            
            NSImage *icon;
            NSString *sizeString;
            NSString *typeString = [NSString stringWithUTF8String:type];
            UTType *utitype;
            NSString *kind;
            
            UTType *folderType = UTTypeFolder;
            
            if([typeString isEqualToString:@"fldr"]) {
                icon = [[NSWorkspace sharedWorkspace] iconForContentType:folderType];
                sizeString = [NSString stringWithFormat:@"%d files", fsize];
                utitype = UTTypeFolder;
                kind = utitype.localizedDescription;
            }
            
            else {
                icon = [[NSWorkspace sharedWorkspace] iconForFileExtension:[name pathExtension]];
                sizeString = [NSByteCountFormatter stringFromByteCount:fsize countStyle:NSByteCountFormatterCountStyleFile];
                NSString *utiString = [name utiStringForFilenameExtension];
                
                if(utiString != nil) {
                    utitype = [UTType typeWithIdentifier:utiString];
                    
                    if(utitype.localizedDescription != nil) {
                        kind = utitype.localizedDescription;
                    }
                    
                    else {
                        kind = @"Unknown Type";
                    }
                }
                
                else {
                    kind = @"Unknown Type";
                }
            }
            
            [icon setSize:NSMakeSize(16,16)];
        
            NSLog(@"kind is: %@", kind);

            // Build the dictionary and add to your model:
            NSDictionary *entry = @{
                @"type":    typeString,
                @"kind":    kind,
                @"icon":    icon,
                @"size":    sizeString,
                @"name":    name
            };
            if (!self.filesModel) self.filesModel = [NSMutableArray array];
            [self.filesModel addObject:entry];
        }
        // advance
        p += objectLen;
    }
    
    NSLog(@"caching %@", self.filePath);
    
    self.directoryCache[self.filePath] = [self.filesModel copy];

    // Refresh UI on main thread:
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.filesTableView reloadData];
    });    
}

- (void)processFileInfoPayload:(NSData*)payload {
    const uint8_t *bytes = payload.bytes;
    NSUInteger      L     = payload.length;
    NSUInteger      pos   = 0;

    // need at least two bytes for the object‐count
    if (L < 2) {
        NSLog(@"⚠️ processFileInfoPayload: payload too short (%lu bytes)", (unsigned long)L);
        return;
    }

    // read how many objects are in here
    uint16_t objectCount = CFSwapInt16BigToHost(*(uint16_t*)(bytes + pos));
    pos += 2;
    NSLog(@"📦 processFileInfoPayload: objectCount = %u", objectCount);

    // loop over each (OID, len, data) triplet
    for (uint16_t i = 0; i < objectCount; i++) {
        if (pos + 4 > L) {
            NSLog(@"    ⚠️ incomplete object[%u] header at offset %lu", i, (unsigned long)pos);
            break;
        }

        uint16_t oid = CFSwapInt16BigToHost(*(uint16_t*)(bytes + pos));
        pos += 2;
        uint16_t len = CFSwapInt16BigToHost(*(uint16_t*)(bytes + pos));
        pos += 2;

        if (pos + len > L) {
            NSLog(@"    ⚠️ object[%u] (OID=%u) length %u overruns buffer (%lu bytes left)",
                  i, oid, len, (unsigned long)(L - pos));
            break;
        }

        // raw-data logging
        NSData *objData = [NSData dataWithBytes:bytes + pos length:len];
        NSLog(@"    • object[%u] → OID=%u, len=%u, raw=%@", i, oid, len, objData);

        // peel off each OID into something useful
        switch (oid) {
          case 201: {   // File name
            NSString *name = [[NSString alloc] initWithBytes:bytes+pos
                                                      length:len
                                                    encoding:NSUTF8StringEncoding] ?: @"<binary>";
            NSLog(@"      ↳ fileName = \"%@\"", name);
          } break;

          case 205: {   // File type string
            NSString *typeStr = [[NSString alloc] initWithBytes:bytes+pos
                                                         length:len
                                                       encoding:NSUTF8StringEncoding] ?: @"<binary>";
            NSLog(@"      ↳ fileTypeString = \"%@\"", typeStr);
          } break;

          case 206: {   // File creator string
            NSString *creator = [[NSString alloc] initWithBytes:bytes+pos
                                                        length:len
                                                      encoding:NSUTF8StringEncoding] ?: @"<binary>";
            NSLog(@"      ↳ fileCreator = \"%@\"", creator);
          } break;

          case 210: {   // File comment
            NSString *comment = [[NSString alloc] initWithBytes:bytes+pos
                                                       length:len
                                                     encoding:NSUTF8StringEncoding] ?: @"<binary>";
            NSLog(@"      ↳ fileComment = \"%@\"", comment);
          } break;

          case 213: {   // File type (four‐char code)
            char code[5] = { bytes[pos], bytes[pos+1], bytes[pos+2], bytes[pos+3], 0 };
            NSLog(@"      ↳ fileTypeCode = '%s'", code);
          } break;

          case 208: {   // Create date (4‐byte Unix timestamp)
            uint32_t ts = CFSwapInt32BigToHost(*(uint32_t*)(bytes + pos));
            NSDate *d = [NSDate dateWithTimeIntervalSince1970:ts];
            NSLog(@"      ↳ createDate = %@", d);
          } break;

          case 209: {   // Modify date
            uint32_t ts = CFSwapInt32BigToHost(*(uint32_t*)(bytes + pos));
            NSDate *d = [NSDate dateWithTimeIntervalSince1970:ts];
            NSLog(@"      ↳ modifyDate = %@", d);
          } break;

          case 207: {   // File size
            uint32_t sz = CFSwapInt32BigToHost(*(uint32_t*)(bytes + pos));
            NSLog(@"      ↳ fileSize = %u bytes", sz);
          } break;

          default:
            // any other OIDs you either skip or log above
            break;
        }

        pos += len;
    }
}

- (void)processDownloadReply:(NSData*)pd {
    NSLog(@"[DEBUG] ← TX202 reply (%lu bytes): %@", (unsigned long)pd.length,
          [NSString hexStringFromData:pd]);

    const uint8_t *buf = pd.bytes;
    NSUInteger       L   = pd.length;
    NSUInteger       p   = 0;

    // pull off object count
    if (L < 2) return;
    uint16_t objCount = CFSwapInt16BigToHost(*(uint16_t*)(buf + p));
    p += 2;
    NSLog(@"    • objectCount = %u", objCount);

    uint32_t transferSize = 0;
    uint32_t fileSize     = 0;
    uint32_t referenceID  = 0;
    uint32_t waitingCount = 0;

    // now walk each (OID,len,data) object
    for (uint16_t i = 0; i < objCount; i++) {
        if (p + 4 > L) break;                 // not enough for OID+len
        uint16_t oid = CFSwapInt16BigToHost(*(uint16_t*)(buf + p));
        p += 2;
        uint16_t len = CFSwapInt16BigToHost(*(uint16_t*)(buf + p));
        p += 2;
        if (p + len > L) break;               // data would overflow

        switch (oid) {
            case 108: {
                transferSize = CFSwapInt32BigToHost(*(uint32_t*)(buf + p));
                NSLog(@"    • OID=108 transferSize=%u", transferSize);
            } break;

            case 207: {
                fileSize = CFSwapInt32BigToHost(*(uint32_t*)(buf + p));
                NSLog(@"    • OID=207 fileSize=%u", fileSize);
            } break;

            case 107: {
                referenceID = CFSwapInt32BigToHost(*(uint32_t*)(buf + p));
                NSLog(@"    • OID=107 referenceID=%u", referenceID);
            } break;

            case 116: {
                if (len == 2) {
                       // 16-bit waiting count
                       waitingCount = CFSwapInt16BigToHost(*(uint16_t*)(buf + p));
                   } else {
                       // fallback if the server ever sends you 4 bytes here
                       waitingCount = CFSwapInt32BigToHost(*(uint32_t*)(buf + p));
                   }
                
                NSLog(@"    • OID=116 waitingCount=%u", waitingCount);
            } break;

            default: {
                NSData *raw = [pd subdataWithRange:NSMakeRange(p, len)];
                NSLog(@"    • OID=%u len=%u raw=%@", oid, len, [NSString hexStringFromData:raw]);
            }
        }

        p += len;
    }

    // kick off the file‐transfer TCP connection once the server says “go”:
    if (waitingCount == 0 && referenceID != 0) {
        FileTransferManager *fileTransfer = [[FileTransferManager alloc]
            initWithHost:self.serverAddress
                     port:self.serverPort
               transferID:referenceID
                 fileName:self.downloadFilename
                 fileSize:transferSize
               txProvider:self.transactions];
        
        fileTransfer.delegate = self;
        
        [self.fileTransfers addObject:fileTransfer];
        
        
        NSMutableDictionary *downloadFileDict = [[NSMutableDictionary alloc] init];
        downloadFileDict[@"name"] = self.downloadFilename;
        downloadFileDict[@"icon"] = [[NSWorkspace sharedWorkspace] iconForFileExtension:[self.downloadFilename pathExtension]];
        downloadFileDict[@"progress"] = [NSNumber numberWithDouble:0];
        downloadFileDict[@"transferID"] = [NSNumber numberWithUnsignedInteger:referenceID];
        downloadFileDict[@"status"] = @"Queued";
        
        
        [self.downloads addObject:downloadFileDict];
        self.downloadsVC.downloads = self.downloads;
        
        [fileTransfer openConnection];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.downloadsVC.tableView reloadData];
            
            [self.downloadsPopover showRelativeToRect:self.downloadButton.bounds
                                               ofView:self.downloadButton
                                        preferredEdge:NSRectEdgeMinY];
            
            
            if(self.downloadsVC.downloads.count > 0) {
                [self.downloadsVC.tableView scrollRowToVisible:self.downloadsVC.downloads.count-1];
            }
            
         });
    }
}

- (void)fileTransferManager:(FileTransferManager*)mgr didReceiveBytes:(NSUInteger)bytesRead {
    
    NSArray *downloads = self.downloadsVC.downloads;

    for (NSUInteger index = 0; index < downloads.count; index++) {
        NSMutableDictionary *downloadFileDict = downloads[index];
        
        if(mgr.transferID == [downloadFileDict[@"transferID"] unsignedIntegerValue]) {
            
            downloadFileDict[@"progress"] = [NSNumber numberWithDouble:(double)mgr.receivedData.length/mgr.fileSize];
            
            NSLog(@"formatted receive data: %@",[NSByteCountFormatter stringFromByteCount:mgr.receivedData.length countStyle:NSByteCountFormatterCountStyleFile]);
            
            if(mgr.fileSize < 4096) {
                downloadFileDict[@"status"] = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:mgr.fileSize countStyle:NSByteCountFormatterCountStyleFile]];
            }
            
            else {
                downloadFileDict[@"status"] = [NSString stringWithFormat:@"%@ of %@", [NSByteCountFormatter stringFromByteCount:mgr.receivedData.length countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:mgr.fileSize countStyle:NSByteCountFormatterCountStyleFile]];
            }
                        
            NSInteger row = index;
            NSIndexSet *rows = [NSIndexSet indexSetWithIndex:row];
            NSIndexSet *cols = [NSIndexSet indexSetWithIndex:
            [self.downloadsVC.tableView columnWithIdentifier:@"download"]];

            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.downloadsVC.tableView reloadDataForRowIndexes:rows
                                                     columnIndexes:cols];
             });
                        
            break;
        }
    }
}

- (void)fileTransferManagerDidFinishTransfer:(FileTransferManager*)mgr {
        
    NSArray *downloads = self.downloadsVC.downloads;

    for (NSUInteger index = 0; index < downloads.count; index++) {
        NSMutableDictionary *downloadFileDict = downloads[index];
        
        if(mgr.transferID == [downloadFileDict[@"transferID"] unsignedIntegerValue]) {
            
            downloadFileDict[@"status"] = [NSString stringWithFormat:@"%@", [NSByteCountFormatter stringFromByteCount:mgr.fileSize countStyle:NSByteCountFormatterCountStyleFile]];
            
            NSInteger row = index;
            NSIndexSet *rows = [NSIndexSet indexSetWithIndex:row];
            NSIndexSet *cols = [NSIndexSet indexSetWithIndex:
            [self.downloadsVC.tableView columnWithIdentifier:@"download"]];

            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.downloadsVC.tableView reloadDataForRowIndexes:rows
                                                     columnIndexes:cols];
             });
            
            
            break;
        }
    }
}

- (void)processUserPrivsPayload:(NSData*)payload {
    const uint8_t *buf = payload.bytes;
    NSUInteger       L   = payload.length;
    NSUInteger       pos = 0;

    if (L >= 2) {
        uint16_t objCount = CFSwapInt16BigToHost(*(uint16_t*)(buf + pos));
        pos += 2;

        for (uint16_t i = 0; i < objCount; i++) {
            if (pos + 4 > L) break;

            uint16_t oid  = CFSwapInt16BigToHost(*(uint16_t*)(buf + pos)); pos += 2;
            uint16_t olen = CFSwapInt16BigToHost(*(uint16_t*)(buf + pos)); pos += 2;
            if (pos + olen > L) break;

            if (oid == 110) {
                if (olen == 8) {
                    // --- NEW: build 64-bit bitmask from those 8 bytes ---
                    
                    NSMutableArray<NSNumber *> *bitArray = [NSMutableArray array];
                    
                    uint8_t raw[8];
                    memcpy(raw, buf + pos, 8);
                    
                    for (int i = 0; i < 8; i++) {
                        uint8_t byte = raw[i];
                        for (int bit = 7; bit >= 0; bit--) {
                            printf("%d", (byte >> bit) & 1);
                            BOOL bitValue = (byte >> bit) & 1;
                            [bitArray addObject:@(bitValue)];
                        }
                    }
                    printf("\n");
                    
                    /*for (int i = 0; i < 8; i++) {
                        uint8_t byte = raw[i];
                        for (int bit = 0; bit < 8; bit++) {
                            BOOL bitValue = (byte >> bit) & 1;
                            [bitArray addObject:@(bitValue)];
                        }
                    }*/
                    
                    /*uint64_t mask = 0;
                    for (NSUInteger b = 0; b < 38; b++) {
                        NSUInteger byteIdx = b / 8;         // which raw byte
                        NSUInteger bitPos  = 7 - (b % 8);   // MSB-first
                        if ((raw[byteIdx] >> bitPos) & 1) {
                            mask |= (1ULL << b);
                        }
                    }
                    
                    self.privs = mask;
                    
                    NSArray<NSNumber*> *bits = [self flagsFromPrivs:mask];
                    NSLog(@"[DEBUG] Priv flags: %@", bits);
                    
                    NSArray<NSString*> *myPrivs = [self decodePrivs:mask];
                    NSLog(@"[DEBUG] User %@ has privileges: %@", self.login, myPrivs);*/
                    
                    int x = 0;
                    
                    NSMutableArray<NSString*> *granted = [NSMutableArray array];
                    
                    for (NSNumber *bitnum in bitArray) {
                        //NSLog(@"bit %d: %d", x, [bitnum intValue]);
                        
                        if([bitnum intValue] == 1) {
                            if(PrivNames[x] != nil) {
                                [granted addObject:PrivNames[x]];
                                NSLog(@"%@", PrivNames[x]);
                            }
                            
                            else {
                                NSLog(@"Priv bit %d not implemented!", x);
                            }
                        }
                                                
                        x++;
                    }
                    
                    self.currentUserPrivs = granted;
                    
                    for(NSString *priv in self.currentUserPrivs) {
                        if([priv isEqualToString:@"Send Broadcast"]) {
                            self.canSendBroadcast = YES;
                        }
                        
                        else if([priv isEqualToString:@"Download File"]) {
                            self.canDownloadFile = YES;
                        }
                        
                        else if([priv isEqualToString:@"Download Folder"]) {
                            self.canDownloadFolder = YES;
                        }
                        
                        else if([priv isEqualToString:@"Upload File"]) {
                            self.canUploadFile = YES;
                        }
                        
                        else if([priv isEqualToString:@"Upload Folder"]) {
                            self.canUploadFolder = YES;
                        }
                        
                        else if([priv isEqualToString:@"News Read Article"]) {
                            self.canReadNews = YES;
                        }
                        
                        else if([priv isEqualToString:@"News Post Article"]) {
                            self.canPostNews = YES;
                        }
                        
                        else if([priv isEqualToString:@"Send Message"]) {
                            self.canSendMessage = YES;
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.window.toolbar validateVisibleItems];
                    });

                }
                break;    // once we’ve handled object 110 we can stop
            }

            pos += olen;
        }
    }
}

#pragma mark - News Processing

- (void)processIncrementalNews:(NSData *)pd {
    const uint8_t *p = pd.bytes;
    uint16_t cnt = ntohs(*(uint16_t*)p); p += 2;
    for (int i = 0; i < cnt; i++) {
        uint16_t oid = ntohs(*(uint16_t*)p); p += 2;
        uint16_t ol  = ntohs(*(uint16_t*)p); p += 2;
        if (oid == 101) {
            NSString *article = [[NSString alloc] initWithBytes:p length:ol encoding:NSUTF8StringEncoding];
            if (article) {
                [self.newsItems insertObject:article atIndex:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.uiState == ClientUIStateNews) {
                        [self.newsTextView setString:[self.newsItems componentsJoinedByString:@"\n"]];
                    }
                });
            }
        }
        p += ol;
    }
}

#pragma mark - Standard Transaction Processing

- (void)processStandardTransaction:(uint16_t)txType payload:(NSData *)pd {
    const uint8_t *p = pd.bytes;
    
    NSUInteger len = pd.length;
    
    // 1️⃣ super‐verbose dump
    NSLog(@"🔍 processStandardTransaction called – raw pd.length = %lu", (unsigned long)len);
    // show the first up to 32 bytes in hex
    NSMutableString *hex = [NSMutableString string];
    for (NSUInteger i = 0; i < MIN(len, 32); i++) {
      [hex appendFormat:@"%02x ", p[i]];
    }
    NSLog(@"    first %lu bytes: %@", (unsigned long)MIN(len,32), hex);

    uint16_t cnt = ntohs(*(uint16_t*)p); p += 2;
    switch (txType) {
        case 301: { // join/rename
            NSMutableDictionary *entry = [NSMutableDictionary dictionary];
            for (int i = 0; i < cnt; i++) {
                uint16_t oid = ntohs(*(uint16_t*)p); p += 2;
                uint16_t ol  = ntohs(*(uint16_t*)p); p += 2;
                NSData   *od = [NSData dataWithBytes:p length:ol];
                p += ol;
                switch (oid) {
                    case 103: entry[@"socket"] = @(ntohs(*(uint16_t*)od.bytes)); break;
                    case 104: entry[@"icon"]   = @(ntohs(*(uint16_t*)od.bytes)); break;
                    case 112: entry[@"status"] = @(ntohs(*(uint16_t*)od.bytes)); break;
                    case 102: entry[@"nick"]   = [[NSString alloc] initWithData:od encoding:NSUTF8StringEncoding]; break;
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *nick = entry[@"nick"];
                NSNumber *sock = entry[@"socket"];
                
                NSUInteger idx = [self.users indexOfObjectPassingTest:^BOOL(NSDictionary *e, NSUInteger idx, BOOL *stop) {
                    return [e[@"socket"] isEqualToNumber:sock];
                }];
                
                if (idx == NSNotFound && nick.length) {
                    [self.users addObject:entry];
                    [self.userListView reloadData];
                    [self appendSpecialNoticeMessage:[NSString stringWithFormat:@"%@ has joined", nick] forType:SpecialNoticeJoinLeave];
                }
                
                else if (idx != NSNotFound) {
                    NSDictionary *old = self.users[idx];
                    NSMutableDictionary *upd = [old mutableCopy];
                    NSString *oldNick = old[@"nick"];
                    
                    if (nick.length) upd[@"nick"] = nick;
                    upd[@"icon"] = entry[@"icon"];
                    upd[@"status"] = entry[@"status"];
                    
                    self.users[idx] = upd;
                    
                    [self.userListView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:idx] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                    
                    if (oldNick.length && nick.length && ![oldNick isEqualToString:nick]) {
                        [self appendSpecialNoticeMessage:[NSString stringWithFormat:@"%@ is now known as %@", oldNick, nick] forType:SpecialNoticeNameChange];
                    }
                }
            });
        } break;
        case 302: { // leave
            for (int i = 0; i < cnt; i++) {
                uint16_t oid = ntohs(*(uint16_t*)p); p += 2;
                uint16_t ol  = ntohs(*(uint16_t*)p); p += 2;
                if (oid == 103 && ol == 2) {
                    uint16_t s = ntohs(*(uint16_t*)p);
                    NSNumber *sock = @(s);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSIndexSet *idxs = [self.users indexesOfObjectsPassingTest:^BOOL(NSDictionary *entry, NSUInteger idx, BOOL *stop) {
                            return [entry[@"socket"] isEqualToNumber:sock];
                        }];
                        if (idxs.count) {
                            NSString *oldNick = [self.users[idxs.firstIndex] objectForKey:@"nick"];
                            [self.users removeObjectsAtIndexes:idxs];
                            [self.userListView reloadData];
                            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowJoinLeaveMessages"] && oldNick.length) {
                                [self appendSpecialNoticeMessage:[NSString stringWithFormat:@"%@ has left", oldNick] forType:SpecialNoticeJoinLeave];
                            }
                        }
                    });
                }
                p += ol;
            }
        } break;
        case 109: { // server agreement
            NSMutableString *agr = [NSMutableString string];
            for (int i = 0; i < cnt; i++) {
                uint16_t oid = ntohs(*(uint16_t*)p); p += 2;
                uint16_t ol  = ntohs(*(uint16_t*)p); p += 2;
                                
                if (oid == 101) [agr appendString:[[NSString alloc] initWithBytes:p length:ol encoding:NSUTF8StringEncoding]];
                p += ol;
            }
            self.serverAgreementMessage = agr;
            
            //NSLog(@"AGREEMENT: %@", self.serverAgreementMessage);
                        
            if(self.showAgreementMessage && [self.serverAgreementMessage isNotEqualTo:@""]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    ShowAgreementViewController *vc = [[ShowAgreementViewController alloc] initWithAgreement:self.serverAgreementMessage];
                    
                    self.agreementSheetWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 360)
                                                                            styleMask:(NSWindowStyleMaskTitled)
                                                                              backing:NSBackingStoreBuffered
                                                                                defer:NO];
                    
                    self.agreementSheetWindow.contentViewController = vc;
                    
                    [self.window beginSheet:self.agreementSheetWindow completionHandler:^(NSModalResponse returnCode) {
                        self.agreementSheetWindow = nil;
                    }];
                });
            }
        } break;
            
        case 104: { // error / private‐message / broadcast
            // first, pull out whatever fields we find
            uint16_t  socketID   = 0;
            uint16_t  errCode    = 0;
            NSString *nick       = nil;
            NSString *text       = nil;

            for (int i = 0; i < cnt; i++) {
                uint16_t oid = ntohs(*(uint16_t*)p); p += 2;
                uint16_t ol  = ntohs(*(uint16_t*)p); p += 2;
                const uint8_t *d = p;

                switch (oid) {
                    case 100: // error code (integer)
                        if (ol >= 2) errCode = ntohs(*(uint16_t*)d);
                        break;

                    case 101: // message text
                        text = [[NSString alloc] initWithBytes:d
                                                       length:ol
                                                     encoding:NSUTF8StringEncoding] ?: @"<unreadable>";
                        break;

                    case 102: // nickname (for private message)
                        nick = [[NSString alloc] initWithBytes:d
                                                       length:ol
                                                     encoding:NSUTF8StringEncoding] ?: @"<unknown>";
                        break;

                    case 103: // socket ID (for private message)
                        if (ol >= 2) socketID = ntohs(*(uint16_t*)d);
                        break;

                    default:
                        break;
                }

                p += ol;
            }

            // now decide which flavor of TX104 we got:
            if (errCode != 0) {
                // ── Error ──
                if (text.length) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [[NSAlert alloc] init];
                        alert.messageText    = [NSString stringWithFormat:@"Server Error %u", errCode];
                        alert.informativeText = text;
                        alert.alertStyle     = NSAlertStyleCritical;
                        [alert addButtonWithTitle:@"OK"];
                        [alert beginSheetModalForWindow:self.window completionHandler:nil];
                    });
                }

            } else if (socketID != 0) {
                // ── Private message ──
                if (text.length) {
                    dispatch_async(dispatch_get_main_queue(), ^{
        
                        [self appendSpecialNoticeMessage:[NSString stringWithFormat:@"%@:  %@", [NSString nickthirteen:nick], text] forType:SpecialNoticePrivateMessage];

                    });
                }

            } else {
                // ── Broadcast ──
                
                if (text.length) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [[NSAlert alloc] init];
                        alert.messageText    = @"Broadcast Message";
                        alert.informativeText = text;
                        alert.alertStyle     = NSAlertStyleInformational;
                        
                        [alert addButtonWithTitle:@"OK"];
                        [alert beginSheetModalForWindow:self.window completionHandler:nil];
                    });
                }
            }
        } break;
        
        case 106: { // chat message
            NSMutableString *chatBuf = [NSMutableString string];
            for (int i = 0; i < cnt; i++) {
                uint16_t oid = ntohs(*(uint16_t*)p); p += 2;
                uint16_t ol  = ntohs(*(uint16_t*)p); p += 2;
                if (oid == 101) {
                    NSString *chat = [[NSString alloc] initWithBytes:p length:ol encoding:NSUTF8StringEncoding];
                    
                    if(chat != nil) {
                        [chatBuf appendString:chat];
                    }
                }
    
                else if (oid == 114 && ol == 4) self.transactions.chatWindowID = ntohl(*(uint32_t*)p);
                p += ol;
            }
            if (chatBuf.length) {
                [self appendToChat:[chatBuf stringByAppendingString:@"\n"]];
            }
        } break;
        default:
            NSLog(@"[DEBUG] Unhandled TX%u, payload length=%lu", txType, (unsigned long)pd.length);
            break;
    }
}

// End of stream handling implementation

#pragma mark – Sending Chat

- (void)appendToChat:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *withNL = [text hasSuffix:@"\n"] ? text : [text stringByAppendingString:@"\n"];
        NSAttributedString *newChat = [[NSAttributedString alloc] initWithString:withNL
                                                                      attributes:@{
                                      NSFontAttributeName: [NSFont userFixedPitchFontOfSize:12],
                                      NSForegroundColorAttributeName: [NSColor textColor]}];
        
        [self.cachedChatContents appendAttributedString:newChat];
        
        NSError *writeError = nil;
        NSAttributedString *stringToSave = self.cachedChatContents;
        NSURL *chatFileURL = [NSURL fileURLWithPath:[[AppSupport chatsURL].path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.rtf", self.serverAddress]]];
        BOOL didWrite = [stringToSave writeToRTFFileURL:chatFileURL error:&writeError];
        if (!didWrite) {
            NSLog(@"❌ Failed to write RTF: %@", writeError.localizedDescription);
        } else {
            NSLog(@"✅ Successfully wrote RTF to %@", chatFileURL.path);
        }
        
        [self.chatTextView setEditable:YES];
        [self.chatTextView.textStorage setAttributedString:self.cachedChatContents];
        [self.chatTextView checkTextInDocument:nil];
        
        NSClipView    *clip     = self.chatScrollView.contentView;
        NSView        *docView  = self.chatScrollView.documentView;
        NSRect         docBounds = docView.bounds;
        NSRect         visBounds = clip.bounds;

        // are we already at (or very near) the bottom?
        CGFloat visibleMaxY   = NSMaxY(visBounds);
        CGFloat documentMaxY  = NSMaxY(docBounds);
        BOOL    isAtBottom    = (visibleMaxY >= documentMaxY - 1);

        if (isAtBottom) {
            // only auto-scroll when the user hasn’t scrolled up
            [self.chatTextView scrollRangeToVisible:
                NSMakeRange(self.chatTextView.string.length, 0)];
        }
        
        //[self.chatTextView scrollToEndOfDocument:self];
        [self.chatTextView setEditable:NO];
    });
}

// Somewhere in your AppDelegate (or wherever you're doing the appends):

- (void)appendSpecialNoticeMessage:(NSString*)msg forType:(SpecialNotice)sn {
    dispatch_async(dispatch_get_main_queue(), ^{

        if(sn == SpecialNoticeJoinLeave) {
            BOOL showJoinLeave = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowJoinLeaveMessages"];
            
            if(!showJoinLeave) {
                return;
            }
        }
        
        else if(sn == SpecialNoticeNameChange) {
            BOOL showNickChange = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowNickChangeMessages"];
            
            if(!showNickChange) {
                return;
            }
        }
        
        if(sn == SpecialNoticeJoinLeave || sn == SpecialNoticeNameChange) {
            
            // Build a centered paragraph style
            NSMutableParagraphStyle *centerStyle = [[NSMutableParagraphStyle alloc] init];
            centerStyle.alignment = NSTextAlignmentCenter;
            centerStyle.paragraphSpacing = 4;
            
            NSDictionary *attrs = @{
                NSForegroundColorAttributeName: [NSColor secondaryLabelColor], // adapts to light/dark
                NSParagraphStyleAttributeName:   centerStyle,
            };
            
            // Create the attributed string, adding a trailing newline
            NSString *line = [msg hasSuffix:@"\n"] ? msg : [msg stringByAppendingString:@"\n"];
            NSAttributedString *attrLine = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", line]
                                                                           attributes:attrs];
            [self.cachedChatContents appendAttributedString:attrLine];
        }
        
        else if(sn == SpecialNoticePrivateMessage) {
            
            NSDictionary *attrs = @{
                NSForegroundColorAttributeName: [NSColor controlAccentColor], // adapts to light/dark
                NSFontAttributeName: [[NSFontManager sharedFontManager]
                        convertFont:[NSFont userFixedPitchFontOfSize:12]
                                      toHaveTrait:NSBoldFontMask],
            };
            
            // Create the attributed string, adding a trailing newline
            NSString *line = [msg hasSuffix:@"\n"] ? msg : [msg stringByAppendingString:@"\n"];
            NSAttributedString *attrLine = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", line]
                                                                           attributes:attrs];
            [self.cachedChatContents appendAttributedString:attrLine];
        }
        
        NSError *writeError = nil;
        NSAttributedString *stringToSave = self.cachedChatContents;
        NSURL *chatFileURL = [NSURL fileURLWithPath:[[AppSupport chatsURL].path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.rtf", self.serverAddress]]];
        BOOL didWrite = [stringToSave writeToRTFFileURL:chatFileURL error:&writeError];
        if (!didWrite) {
            NSLog(@"❌ Failed to write RTF: %@", writeError.localizedDescription);
        } else {
            NSLog(@"✅ Successfully wrote RTF to %@", chatFileURL.path);
        }
        
        [self.chatTextView setEditable:YES];
        [self.chatTextView.textStorage setAttributedString:self.cachedChatContents];
        [self.chatTextView checkTextInDocument:nil];
        
        NSClipView    *clip     = self.chatScrollView.contentView;
        NSView        *docView  = self.chatScrollView.documentView;
        NSRect         docBounds = docView.bounds;
        NSRect         visBounds = clip.bounds;

        // are we already at (or very near) the bottom?
        CGFloat visibleMaxY   = NSMaxY(visBounds);
        CGFloat documentMaxY  = NSMaxY(docBounds);
        BOOL    isAtBottom    = (visibleMaxY >= documentMaxY - 1);

        if (isAtBottom) {
            // only auto-scroll when the user hasn’t scrolled up
            [self.chatTextView scrollRangeToVisible:
                NSMakeRange(self.chatTextView.string.length, 0)];
        }
        
        //[self.chatTextView scrollToEndOfDocument:self];
        [self.chatTextView setEditable:NO];
    });
}

// Send button handler
- (void)onSend:(id)sender {
    NSString *text = self.messageField.stringValue;
    if(text.length==0) return;
    
    BOOL isEmote = NO;

    if([text hasPrefix:@"/msg"]) {
        NSArray<NSString*> *parts = [text componentsSeparatedByString:@" "];

        if (parts.count >= 3) {
            NSString *command = parts[0];
            NSString *name    = parts[1];
            
            // 2. Compute where the “message” really starts in the original string
            NSUInteger offset = command.length + 1 + name.length + 1;
            NSString *message = [text substringFromIndex:offset];
            
            NSLog(@"command = %@", command); // "/msg"
            NSLog(@"name    = %@", name);    // "name"
            NSLog(@"message = %@", message); // "text with spaces"
            
            uint16_t socket = [self getSocketForNick:name];

            if(socket != 0) {
                
                if(self.canSendMessage == YES) {
                    [self.transactions sendPrivateMessageTransaction:message toSocket:socket forStream:self.outputStream];
                    [self appendSpecialNoticeMessage:[NSString stringWithFormat:@"%@:  %@", [NSString nickthirteen:self.nickname], message] forType:SpecialNoticePrivateMessage];
                }
            }
        }
    }
    
    // if it starts with "/me ", strip it and mark as emote
    else if ([text hasPrefix:@"/me"]) {
        isEmote = YES;
        // send with the appropriate flag
        [self.transactions sendChatTransaction:[text substringFromIndex:3] asEmote:isEmote forStream:self.outputStream];
    }
    
    else {
        // send with the appropriate flag
        [self.transactions sendChatTransaction:text asEmote:isEmote forStream:self.outputStream];
    }

    // clear the field
    self.messageField.stringValue = @"";
}

/// Returns an array of 64 NSNumber<BOOL> values, one per bit in the mask.
- (NSArray<NSNumber*>*)flagsFromPrivs:(uint64_t)privs {
    NSMutableArray<NSNumber*> *flags = [NSMutableArray arrayWithCapacity:64];
    for (uint8_t bit = 0; bit < 64; bit++) {
        BOOL isSet = ((privs >> bit) & 1ULL) != 0;
        [flags addObject:@(isSet)];
    }
    return flags;
}

/// Returns an NSArray<NSString*> of all privilege names set in `privs`.
- (NSArray<NSString*>*)decodePrivs:(uint64_t)privs {
    NSUInteger count = sizeof(PrivNames)/sizeof(PrivNames[0]);
    NSMutableArray<NSString*> *granted = [NSMutableArray array];
    for (NSUInteger bit = 0; bit < count; bit++) {
        if ((privs >> bit) & 1ULL) {
            [granted addObject:PrivNames[bit]];
        }
    }
    return granted;
}

/// Returns the correct data to send for the password object:
///  - If the password is exactly the control-G character, or empty, returns a single NUL byte.
///  - Otherwise returns UTF-8 bytes of the string.
- (NSData*)passwordBytesForModify {
    if (self.openUserPassword.length == 1 &&
        [self.openUserPassword characterAtIndex:0] == 0x07) {
        // server-sent “bell” → send NUL
        uint8_t zero = 0;
        return [NSData dataWithBytes:&zero length:1];
    }
    else if (self.openUserPassword.length == 0) {
        // no password change → send NUL
        uint8_t zero = 0;
        return [NSData dataWithBytes:&zero length:1];
    }
    else {
        // user-specified new password → send UTF8
        return [self.openUserPassword dataUsingEncoding:NSUTF8StringEncoding];
    }
}
@end
